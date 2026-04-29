import 'package:flutter/material.dart';
import 'signature_path_point.dart';

class SignatureCanvas extends StatelessWidget {
  final List<SignaturePoint> points;
  final Color color;
  final double strokeWidth;

  const SignatureCanvas({
    super.key,
    required this.points,
    required this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SignaturePainter(
        points: points,
        color: color,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<SignaturePoint> points;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (!points[i].isBreak && !points[i + 1].isBreak) {
        canvas.drawLine(points[i].point, points[i + 1].point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
