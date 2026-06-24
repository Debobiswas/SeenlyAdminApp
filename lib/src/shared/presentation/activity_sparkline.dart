import 'package:flutter/material.dart';

class ActivitySparkline extends StatelessWidget {
  const ActivitySparkline({
    required this.dataPoints,
    this.lineColor,
    this.fillColor,
    this.lineWidth = 2.0,
    super.key,
  });

  final List<double> dataPoints;
  final Color? lineColor;
  final Color? fillColor;
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = lineColor ?? theme.colorScheme.primary;
    final fill = fillColor ?? theme.colorScheme.primary.withValues(alpha: 0.22);

    return CustomPaint(
      painter: _SparklinePainter(
        dataPoints: dataPoints,
        lineColor: primary,
        fillColor: fill,
        lineWidth: lineWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillColor,
    required this.lineWidth,
  });

  final List<double> dataPoints;
  final Color lineColor;
  final Color fillColor;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final width = size.width;
    final height = size.height;

    // Normalizing values
    final maxVal = dataPoints.reduce((curr, next) => curr > next ? curr : next);
    final minVal = dataPoints.reduce((curr, next) => curr < next ? curr : next);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final points = <Offset>[];
    final stepX = width / (dataPoints.length - 1);

    for (var i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // Map Y to fit nicely within a padded region inside the container
      final normalizedY = (dataPoints[i] - minVal) / range;
      final y = height - (normalizedY * height * 0.7 + height * 0.15);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Draw smooth bezier curves
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + stepX / 2, p0.dy);
      final controlPoint2 = Offset(p1.dx - stepX / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    // Fill the path
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor,
          fillColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line path
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
