import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/models/venue.dart';

class VenueRadarMap extends StatefulWidget {
  const VenueRadarMap({required this.venues, super.key});

  final List<Venue> venues;

  @override
  State<VenueRadarMap> createState() => _VenueRadarMapState();
}

class _VenueRadarMapState extends State<VenueRadarMap> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.venues.isEmpty) {
      return const Center(
        child: Text('No venues with coordinates to display on radar map.'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.brightness == Brightness.light
            ? Colors.blueGrey.shade900
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _RadarPainter(
                venues: widget.venues,
                sweepAngle: _animationController.value * 2 * pi,
                primaryColor: theme.colorScheme.primary,
                secondaryColor: theme.colorScheme.secondary,
              ),
              child: Container(),
            );
          },
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.venues,
    required this.sweepAngle,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<Venue> venues;
  final double sweepAngle;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 * 0.9;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 1. Draw concentric circles
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), gridPaint);
    }

    // 2. Draw crosshairs
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    // 3. Draw sweeping line (radar beam)
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.4),
          primaryColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      sweepAngle - 0.4,
      0.4,
      true,
      sweepPaint,
    );

    // 4. Plot venues relative to their latitude/longitude
    // Calculate bounding box for normalization
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final v in venues) {
      if (v.latitude < minLat) minLat = v.latitude;
      if (v.latitude > maxLat) maxLat = v.latitude;
      if (v.longitude < minLng) minLng = v.longitude;
      if (v.longitude > maxLng) maxLng = v.longitude;
    }

    // Adjust in case lat/lng are identical
    final latRange = (maxLat - minLat).abs() < 0.0001 ? 1.0 : (maxLat - minLat);
    final lngRange = (maxLng - minLng).abs() < 0.0001 ? 1.0 : (maxLng - minLng);

    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final v in venues) {
      // Normalize to -1 to 1 range relative to center
      final normX = ((v.longitude - minLng) / lngRange) * 2 - 1;
      final normY = -(((v.latitude - minLat) / latRange) * 2 - 1); // Flip Y for screen coords

      // Scale to radar constraints (multiply by 0.75 so they stay within circle bounds)
      final pt = Offset(
        center.dx + normX * maxRadius * 0.75,
        center.dy + normY * maxRadius * 0.75,
      );

      // Draw dot glow
      final glowPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pt, 10, glowPaint);

      // Draw dot center
      canvas.drawCircle(pt, 5, dotPaint);

      // Draw label/initials
      textPainter.text = TextSpan(
        text: v.name.length > 8 ? '${v.name.substring(0, 7)}..' : v.name,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx + 8, pt.dy - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.venues != venues;
  }
}
