import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Row of equal segments showing progress through a fixed number of steps.
///
/// [current] is 1-based; segments 1..[current] are filled.
class SegmentedStepProgress extends StatelessWidget {
  const SegmentedStepProgress({
    super.key,
    required this.current,
    required this.total,
    this.width = 144,
  }) : assert(total > 0),
       assert(current >= 0 && current <= total);

  final int current;
  final int total;

  /// Null to fill the available width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $current of $total',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: 6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < current ? AppColors.primary : AppColors.track,
                    borderRadius: AppRadii.pillRadius,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded horizontal progress bar.
///
/// Not animated, so it is safe on timed exam screens.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.trackColor = AppColors.track,
    this.height = 8,
    this.semanticLabel,
  });

  /// 0.0 to 1.0.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()}%',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadii.pillRadius,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: trackColor)),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: clamped,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadii.pillRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ring-shaped progress with an optional widget in the middle.
///
/// Not animated, so it is safe on timed exam screens.
class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.color = AppColors.primary,
    this.trackColor = AppColors.track,
    this.center,
    this.semanticLabel,
  });

  /// 0.0 to 1.0.
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: clamped,
            strokeWidth: strokeWidth,
            color: color,
            trackColor: trackColor,
            // Progress runs clockwise in LTR, counter-clockwise in RTL.
            clockwise: Directionality.of(context) == TextDirection.ltr,
          ),
          child: center == null ? null : Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.clockwise,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final bool clockwise;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = trackColor);
    if (value <= 0) return;
    final sweep = math.pi * 2 * value * (clockwise ? 1 : -1);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.clockwise != clockwise;
}
