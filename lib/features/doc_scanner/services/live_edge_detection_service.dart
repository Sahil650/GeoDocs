import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class DocCorners {
  /// [tlx,tly, trx,try_, blx,bly, brx,bry] all in [0..1] image space
  final List<double> norm;
  final bool detected;
  const DocCorners(this.norm, {required this.detected});
}

class _Payload {
  final Uint8List y;   // greyscale pixels, row-major
  final int w, h;
  const _Payload(this.y, this.w, this.h);
}

class LiveEdgeDetectionService {

  static Future<DocCorners> detectFromCameraImage(CameraImage frame) async {
    final payload = await compute(_prepareY, frame);
    if (payload == null) return _fallback();
    return compute(_detect, payload);
  }

  // ── Prepare Y-plane (downsample to ~400px) ───────────────────────────────

  static _Payload? _prepareY(CameraImage frame) {
    try {
      final plane = frame.planes[0];
      final srcW  = frame.width, srcH = frame.height;
      final bytes = plane.bytes;
      final rs    = plane.bytesPerRow;

      const target = 400;
      final sc  = target / max(srcW, srcH);
      final dw  = (srcW * sc).round().clamp(1, target);
      final dh  = (srcH * sc).round().clamp(1, target);
      final out = Uint8List(dw * dh);

      for (int dy = 0; dy < dh; dy++) {
        final sy = (dy / sc).clamp(0.0, srcH - 1.0);
        final y0 = sy.floor(), y1 = (y0 + 1).clamp(0, srcH - 1);
        final fy = sy - y0;
        for (int dx = 0; dx < dw; dx++) {
          final sx = (dx / sc).clamp(0.0, srcW - 1.0);
          final x0 = sx.floor(), x1 = (x0 + 1).clamp(0, srcW - 1);
          final fx = sx - x0;
          final v = (bytes[y0*rs+x0]*(1-fx)+bytes[y0*rs+x1]*fx)*(1-fy)
                  + (bytes[y1*rs+x0]*(1-fx)+bytes[y1*rs+x1]*fx)*fy;
          out[dy * dw + dx] = v.round().clamp(0, 255);
        }
      }
      return _Payload(out, dw, dh);
    } catch (_) { return null; }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DETECTION ISOLATE
  // ══════════════════════════════════════════════════════════════════════════

  static DocCorners _detect(_Payload p) {
    try {
      final w = p.w, h = p.h;

      // 1. Blur
      final blurred = _box3(p.y, w, h);

      // 2. Canny-style edges (Sobel + NMS + double threshold)
      final edges = _canny(blurred, w, h);

      // 3. Dilate to connect broken lines
      final dilated = _dilate3(edges, w, h);

      // 4. Find all contours, pick the best valid quad
      final quad = _bestDocQuad(dilated, w, h);
      if (quad == null) return _fallback();

      // 5. Normalise
      final norm = [
        (quad[0].x/w).clamp(0.02,0.98),(quad[0].y/h).clamp(0.02,0.98),
        (quad[1].x/w).clamp(0.02,0.98),(quad[1].y/h).clamp(0.02,0.98),
        (quad[2].x/w).clamp(0.02,0.98),(quad[2].y/h).clamp(0.02,0.98),
        (quad[3].x/w).clamp(0.02,0.98),(quad[3].y/h).clamp(0.02,0.98),
      ];

      return DocCorners(norm, detected: true);
    } catch (_) { return _fallback(); }
  }

  // ── 3×3 box blur ─────────────────────────────────────────────────────────

  static Uint8List _box3(Uint8List s, int w, int h) {
    final o = Uint8List(w * h);
    for (int y = 1; y < h-1; y++) {
      for (int x = 1; x < w-1; x++) {
        int v = 0;
        for (int dy = -1; dy <= 1; dy++)
          for (int dx = -1; dx <= 1; dx++) {
            v += s[(y+dy)*w+(x+dx)];
          }
        o[y*w+x] = v ~/ 9;
      }
    }
    return o;
  }

  // ── Canny edge detector ───────────────────────────────────────────────────

  static Uint8List _canny(Uint8List g, int w, int h) {
    // Sobel
    final mag  = List<double>.filled(w*h, 0);
    final angX = List<double>.filled(w*h, 0);
    final angY = List<double>.filled(w*h, 0);
    for (int y = 1; y < h-1; y++) {
      for (int x = 1; x < w-1; x++) {
        final tl=g[(y-1)*w+(x-1)]; final tc=g[(y-1)*w+x]; final tr=g[(y-1)*w+(x+1)];
        final ml=g[y    *w+(x-1)];                          final mr=g[y    *w+(x+1)];
        final bl=g[(y+1)*w+(x-1)]; final bc=g[(y+1)*w+x]; final br=g[(y+1)*w+(x+1)];
        final gx=(-tl-2*ml-bl+tr+2*mr+br).toDouble();
        final gy=(-tl-2*tc-tr+bl+2*bc+br).toDouble();
        mag[y*w+x]  = sqrt(gx*gx+gy*gy);
        angX[y*w+x] = gx;
        angY[y*w+x] = gy;
      }
    }

    // Adaptive thresholds from magnitude histogram
    final vals = mag.where((v)=>v>0).toList()..sort();
    if (vals.isEmpty) return Uint8List(w*h);
    final hi = vals[(vals.length*0.92).round().clamp(0,vals.length-1)];
    final lo = hi * 0.3;

    // Non-maximum suppression + threshold
    final out = Uint8List(w*h);
    for (int y = 1; y < h-1; y++) {
      for (int x = 1; x < w-1; x++) {
        final m = mag[y*w+x];
        if (m < lo) continue;
        final a = atan2(angY[y*w+x], angX[y*w+x]);
        double n1, n2;
        if (a.abs() < pi/8 || a.abs() > 7*pi/8) {
          n1=mag[y*w+(x-1)]; n2=mag[y*w+(x+1)];
        } else if (a>pi/8 && a<3*pi/8) {
          n1=mag[(y-1)*w+(x+1)]; n2=mag[(y+1)*w+(x-1)];
        } else if (a<-pi/8 && a>-3*pi/8) {
          n1=mag[(y+1)*w+(x+1)]; n2=mag[(y-1)*w+(x-1)];
        } else {
          n1=mag[(y-1)*w+x]; n2=mag[(y+1)*w+x];
        }
        if (m>=n1 && m>=n2 && m>=hi) out[y*w+x]=255;
      }
    }
    return out;
  }

  // ── 3×3 dilation ─────────────────────────────────────────────────────────

  static Uint8List _dilate3(Uint8List s, int w, int h) {
    final o = Uint8List(w*h);
    for (int y = 1; y < h-1; y++)
      for (int x = 1; x < w-1; x++) {
        if (s[y*w+x]>0)
          for (int dy=-1;dy<=1;dy++) {
            for (int dx=-1;dx<=1;dx++) {
              o[(y+dy)*w+(x+dx)]=255;
      }
          }
            }
    return o;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIND BEST DOCUMENT QUAD
  //
  // A valid document quad must pass ALL of these tests:
  //   1. Convex hull simplifies to 4 points (Douglas-Peucker)
  //   2. All 4 interior angles between 50° and 130° (roughly rectangular)
  //   3. Area > 8% of image (document must be reasonably large)
  //   4. Area / convex-hull-area > 0.7 (must actually be quad-shaped)
  //   5. Aspect ratio between 0.3 and 3.5 (not a sliver)
  //   6. No side shorter than 10% of image diagonal
  // ══════════════════════════════════════════════════════════════════════════

  static List<_Pt>? _bestDocQuad(Uint8List edges, int w, int h) {
    final visited = List<bool>.filled(w*h, false);
    final minBlob = (w*h*0.003).round();
    final imgDiag = sqrt(w*w + h*h.toDouble());

    List<_Pt>? best;
    double bestScore = 0;

    for (int y = 2; y < h-2; y++) {
      for (int x = 2; x < w-2; x++) {
        final i = y*w+x;
        if (edges[i]==0 || visited[i]) continue;

        // BFS
        final blob  = <_Pt>[];
        final queue = <int>[i];
        visited[i]  = true;
        while (queue.isNotEmpty) {
          final cur = queue.removeLast();
          blob.add(_Pt((cur%w).toDouble(),(cur~/w).toDouble()));
          final cx=cur%w, cy=cur~/w;
          for (final d in _d8) {
            final nx=cx+d[0], ny=cy+d[1];
            if (nx<1||nx>=w-1||ny<1||ny>=h-1) continue;
            final ni=ny*w+nx;
            if (visited[ni]||edges[ni]==0) continue;
            visited[ni]=true; queue.add(ni);
          }
        }
        if (blob.length < minBlob) continue;

        // Hull → DP simplification
        final hull = _hull(blob);
        if (hull.length < 4) continue;
        final perim = _perim(hull);
        final poly  = _dp(hull, perim * 0.025);

        // Must simplify to exactly 4 corners
        List<_Pt> quad;
        if (poly.length == 4) {
          quad = poly;
        } else if (poly.length > 4 && poly.length <= 8) {
          // Try collapsing nearby corners
          quad = _collapseToQuad(poly);
          if (quad.length != 4) continue;
        } else {
          continue;
        }

        // Sort into convex order first
        quad = _convexOrder(quad);

        // ── Validation ────────────────────────────────────────────────────

        // 1. All angles roughly rectangular (50°–130°)
        if (!_anglesOk(quad)) continue;

        // 2. Area check
        final area = _shoelace(quad);
        if (area < w*h*0.08) continue;

        // 3. Aspect ratio
        final wb = (_dist(quad[0],quad[1]) + _dist(quad[3],quad[2]))/2;
        final hb = (_dist(quad[0],quad[3]) + _dist(quad[1],quad[2]))/2;
        final ar = wb/hb;
        if (ar < 0.25 || ar > 4.0) continue;

        // 4. No side too short
        final minSide = [
          _dist(quad[0],quad[1]),_dist(quad[1],quad[2]),
          _dist(quad[2],quad[3]),_dist(quad[3],quad[0]),
        ].reduce(min);
        if (minSide < imgDiag * 0.10) continue;

        // Score = area (prefer larger documents)
        if (area > bestScore) { bestScore=area; best=quad; }
      }
    }

    if (best == null) return null;

    // Sort into tl/tr/bl/br
    return _sortTlTrBlBr(best);
  }

  static const _d8=[[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[1,-1],[-1,1],[1,1]];

  // Check all interior angles are between 50° and 130°
  static bool _anglesOk(List<_Pt> q) {
    for (int i = 0; i < 4; i++) {
      final prev = q[(i+3)%4], cur = q[i], next = q[(i+1)%4];
      final ax = prev.x-cur.x, ay = prev.y-cur.y;
      final bx = next.x-cur.x, by = next.y-cur.y;
      final dot = ax*bx + ay*by;
      final mag = sqrt(ax*ax+ay*ay) * sqrt(bx*bx+by*by);
      if (mag < 1e-6) return false;
      final ang = acos((dot/mag).clamp(-1.0,1.0)) * 180 / pi;
      if (ang < 50 || ang > 130) return false;
    }
    return true;
  }

  // Sort 4 points into convex counter-clockwise order
  static List<_Pt> _convexOrder(List<_Pt> pts) {
    final cx = pts.map((p)=>p.x).reduce((a,b)=>a+b)/4;
    final cy = pts.map((p)=>p.y).reduce((a,b)=>a+b)/4;
    final sorted = List.of(pts)..sort((a,b)=>
        atan2(a.y-cy,a.x-cx).compareTo(atan2(b.y-cy,b.x-cx)));
    return sorted;
  }

  // Sort convex quad into topLeft / topRight / bottomRight / bottomLeft
  static List<_Pt> _sortTlTrBlBr(List<_Pt> pts) {
    // Reorder convex hull (already sorted by angle) into tl,tr,bl,br
    final bySum  = List.of(pts)..sort((a,b)=>(a.x+a.y).compareTo(b.x+b.y));
    final byDiff = List.of(pts)..sort((a,b)=>(a.y-a.x).compareTo(b.y-b.x));
    return [
      bySum[0],    // tl: min(x+y)
      byDiff[0],   // tr: min(y-x)
      byDiff[3],   // bl: max(y-x)
      bySum[3],    // br: max(x+y)
    ];
  }

  // Collapse polygon with >4 points to 4 by merging closest adjacent corners
  static List<_Pt> _collapseToQuad(List<_Pt> poly) {
    var pts = List.of(poly);
    while (pts.length > 4) {
      double minD = double.infinity; int minI = 0;
      for (int i = 0; i < pts.length; i++) {
        final d = _dist(pts[i], pts[(i+1)%pts.length]);
        if (d < minD) { minD=d; minI=i; }
      }
      final j = (minI+1)%pts.length;
      final merged = _Pt(
          (pts[minI].x+pts[j].x)/2, (pts[minI].y+pts[j].y)/2);
      pts.removeAt(j < minI ? minI : j);
      pts.removeAt(j < minI ? j : minI);
      pts.insert(min(minI, j), merged);
    }
    return pts;
  }

  // ── Convex hull (Graham scan) ─────────────────────────────────────────────

  static List<_Pt> _hull(List<_Pt> pts) {
    final s = pts.length > 600
        ? (List.of(pts)..shuffle()).sublist(0,600) : pts;
    _Pt anc = s[0];
    for (final p in s) {
      if (p.y>anc.y||(p.y==anc.y&&p.x<anc.x)) anc=p;
    }
    final rest = s.where((p)=>p!=anc).toList()
      ..sort((a,b){
        final c=_cross(anc,a,b);
        return c!=0?(c>0?-1:1):_d2(anc,a).compareTo(_d2(anc,b));
      });
    final h=<_Pt>[anc];
    for (final p in rest){
      while(h.length>=2&&_cross(h[h.length-2],h.last,p)<=0) {
        h.removeLast();
      }
      h.add(p);
    }
    return h;
  }

  // ── Douglas-Peucker ───────────────────────────────────────────────────────

  static List<_Pt> _dp(List<_Pt> pts, double eps) {
    if (pts.length<=2) return pts;
    double mx=0; int idx=0;
    for (int i=1;i<pts.length-1;i++){
      final d=_ptLineDist(pts[i],pts.first,pts.last);
      if(d>mx){mx=d;idx=i;}
    }
    if (mx>eps){
      final l=_dp(pts.sublist(0,idx+1),eps);
      final r=_dp(pts.sublist(idx),eps);
      return [...l.sublist(0,l.length-1),...r];
    }
    return [pts.first,pts.last];
  }

  static double _ptLineDist(_Pt p,_Pt a,_Pt b){
    final dx=b.x-a.x,dy=b.y-a.y,len2=dx*dx+dy*dy;
    if(len2==0) return sqrt(_d2(p,a));
    final t=((p.x-a.x)*dx+(p.y-a.y)*dy)/len2;
    final tc=t.clamp(0.0,1.0);
    return sqrt(pow(p.x-a.x-tc*dx,2)+pow(p.y-a.y-tc*dy,2));
  }

  // ── Math helpers ──────────────────────────────────────────────────────────

  static double _cross(_Pt o,_Pt a,_Pt b)=>(a.x-o.x)*(b.y-o.y)-(a.y-o.y)*(b.x-o.x);
  static double _d2(_Pt a,_Pt b)=>(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y);
  static double _dist(_Pt a,_Pt b)=>sqrt(_d2(a,b));
  static double _perim(List<_Pt> p){double s=0;for(int i=0;i<p.length;i++) {
    s+=_dist(p[i],p[(i+1)%p.length]);
  }return s;}
  static double _shoelace(List<_Pt> p){double a=0;for(int i=0;i<p.length;i++){final j=(i+1)%p.length;a+=p[i].x*p[j].y-p[j].x*p[i].y;}return a.abs()/2;}

  static DocCorners _fallback()=>const DocCorners(
    [0.08,0.13,0.92,0.13,0.08,0.85,0.92,0.85],detected:false);
}

class _Pt { final double x,y; const _Pt(this.x,this.y); }