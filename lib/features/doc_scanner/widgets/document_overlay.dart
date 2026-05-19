import 'package:flutter/material.dart';

class DocumentOverlay extends StatelessWidget {

  const DocumentOverlay({super.key});

  @override
  Widget build(BuildContext context) {

    return IgnorePointer(

      child: CustomPaint(

        painter: BorderPainter(),
      ),
    );
  }
}

class BorderPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = Colors.yellow

      ..strokeWidth = 4

      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(

      size.width * .1,

      size.height * .2,

      size.width * .8,

      size.height * .5,
    );

    canvas.drawRect(rect, paint);

    drawCorner(canvas, rect.topLeft);
    drawCorner(canvas, rect.topRight);
    drawCorner(canvas, rect.bottomLeft);
    drawCorner(canvas, rect.bottomRight);
  }

  void drawCorner(Canvas canvas, Offset point){

    final paint = Paint()

      ..color = Colors.yellow

      ..strokeWidth = 6;

    canvas.drawCircle(point, 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {

    return false;
  }
}