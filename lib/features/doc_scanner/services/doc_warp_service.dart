import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class _Pay {
  final Uint8List bytes;
  final List<double> norm; // [tlx,tly, trx,try_, blx,bly, brx,bry] in [0..1]
  final String filter;
  const _Pay(this.bytes, this.norm, this.filter);
}

class DocWarpService {

  static Future<File> warpAndFilter({
    required File file,
    required List<double> norm,
    required String filter,
  }) async {
    assert(norm.length == 8);
    final bytes = Uint8List.fromList(await file.readAsBytes());
    final out   = await compute(_run, _Pay(bytes, norm, filter));
    final dir   = await getTemporaryDirectory();
    final f     = File(p.join(dir.path, '${const Uuid().v4()}.jpg'));
    await f.writeAsBytes(out);
    return f;
  }

  static Uint8List _run(_Pay pay) {
    final src = img.decodeImage(pay.bytes)!;
    final iw  = src.width.toDouble();
    final ih  = src.height.toDouble();
    final n   = pay.norm;

    // Convert normalised → actual image pixel coords
    final tlx=n[0]*iw, tly=n[1]*ih;
    final trx=n[2]*iw, try_=n[3]*ih;
    final blx=n[4]*iw, bly=n[5]*ih;
    final brx=n[6]*iw, bry=n[7]*ih;

    // Output rect size = average of opposite edge lengths
    final wT = _dist(tlx,tly,trx,try_);
    final wB = _dist(blx,bly,brx,bry);
    final hL = _dist(tlx,tly,blx,bly);
    final hR = _dist(trx,try_,brx,bry);
    final ow = ((wT+wB)/2).round().clamp(10,6000);
    final oh = ((hL+hR)/2).round().clamp(10,6000);

    // Solve 8-DOF homography H mapping every output (dst) pixel → source pixel
    final H = _solveH(
      [0.0,0.0],[ow-1.0,0.0],[0.0,oh-1.0],[ow-1.0,oh-1.0],  // dst: tl tr bl br
      [tlx,tly],[trx,try_],  [blx,bly],   [brx,bry],          // src: tl tr bl br
    );

    final dst = img.Image(width: ow, height: oh);

    for (int dy = 0; dy < oh; dy++) {
      for (int dx = 0; dx < ow; dx++) {
        final denom = H[6]*dx + H[7]*dy + 1.0;
        final sx    = (H[0]*dx + H[1]*dy + H[2]) / denom;
        final sy    = (H[3]*dx + H[4]*dy + H[5]) / denom;

        if (sx < 0 || sy < 0 || sx >= iw-1 || sy >= ih-1) {
          dst.setPixelRgb(dx, dy, 255, 255, 255);
          continue;
        }

        // Bilinear interpolation
        final x0=sx.floor(), y0=sy.floor();
        final fx=sx-x0,      fy=sy-y0;
        final p00=src.getPixel(x0,   y0  );
        final p10=src.getPixel(x0+1, y0  );
        final p01=src.getPixel(x0,   y0+1);
        final p11=src.getPixel(x0+1, y0+1);

        int bl(double a,double b,double c,double d) =>
            ((a*(1-fx)+b*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy).round().clamp(0,255);

        dst.setPixelRgb(dx,dy,
          bl(p00.r.toDouble(),p10.r.toDouble(),p01.r.toDouble(),p11.r.toDouble()),
          bl(p00.g.toDouble(),p10.g.toDouble(),p01.g.toDouble(),p11.g.toDouble()),
          bl(p00.b.toDouble(),p10.b.toDouble(),p01.b.toDouble(),p11.b.toDouble()),
        );
      }
    }

    return Uint8List.fromList(img.encodeJpg(_applyFilter(dst,pay.filter), quality:93));
  }

  static double _dist(double x1,double y1,double x2,double y2) =>
      sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));

  // DLT homography solver
  static List<double> _solveH(
    List<double> dTL,List<double> dTR,List<double> dBL,List<double> dBR,
    List<double> sTL,List<double> sTR,List<double> sBL,List<double> sBR,
  ) {
    final ds=[dTL,dTR,dBL,dBR], ss=[sTL,sTR,sBL,sBR];
    final A=List.generate(8,(_)=>List<double>.filled(8,0.0));
    final b=List<double>.filled(8,0.0);
    for (int i=0;i<4;i++){
      final dx=ds[i][0],dy=ds[i][1],sx=ss[i][0],sy=ss[i][1];
      A[2*i  ]=[dx,dy,1,0,0,0,-sx*dx,-sx*dy]; b[2*i  ]=sx;
      A[2*i+1]=[0,0,0,dx,dy,1,-sy*dx,-sy*dy]; b[2*i+1]=sy;
    }
    return _gauss(A,b);
  }

  static List<double> _gauss(List<List<double>> A,List<double> b){
    const n=8;
    final M=List.generate(n,(i)=>[...A[i],b[i]]);
    for(int c=0;c<n;c++){
      int piv=c;
      for(int r=c+1;r<n;r++) {
        if(M[r][c].abs()>M[piv][c].abs()) piv=r;
      }
      final t=M[c]; M[c]=M[piv]; M[piv]=t;
      if(M[c][c].abs()<1e-12) continue;
      for(int r=0;r<n;r++){
        if(r==c) continue;
        final f=M[r][c]/M[c][c];
        for(int k=c;k<=n;k++) {
          M[r][k]-=f*M[c][k];
        }
      }
    }
    return List.generate(n,(i)=>M[i][n]/M[i][i]);
  }

  static img.Image _applyFilter(img.Image src, String f) {
    switch(f){
      case 'bw':      return img.grayscale(src);
      case 'gray':    return img.adjustColor(img.grayscale(src),
                          contrast:1.2, brightness:1.02);
      case 'enhance': return img.adjustColor(src,
                          contrast:1.35, saturation:1.1, brightness:1.05);
      case 'sharp':   return img.convolution(src,
                          filter:[0,-1,0,-1,5,-1,0,-1,0],div:1,offset:0);
      default:        return src;
    }
  }
}