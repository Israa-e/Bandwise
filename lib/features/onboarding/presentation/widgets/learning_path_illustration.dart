import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Decorative learning path for the Welcome screen: a curved route from a
/// first skill, through daily practice, to the user's goal.
///
/// Hidden from screen readers; mirrored in RTL.
class LearningPathIllustration extends StatelessWidget {
  const LearningPathIllustration({super.key});

  static const _height = 220.0;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: AppColors.selectedSurface,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PathPainter(mirrored: rtl)),
            ),
            const PositionedDirectional(
              start: 20,
              bottom: 16,
              child: _StartNode(),
            ),
            const Align(alignment: Alignment(0, -0.12), child: _PracticeNode()),
            const PositionedDirectional(top: 18, end: 18, child: _GoalNode()),
            const PositionedDirectional(
              top: 18,
              start: 18,
              child: _FloatingBadge(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warning,
                label: 'Daily streak',
              ),
            ),
            const PositionedDirectional(
              bottom: 18,
              end: 18,
              child: _FloatingBadge(
                icon: Icons.rate_review_outlined,
                iconColor: AppColors.primary,
                label: 'Writing & speaking feedback',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.mirrored});

  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    // Designed on a 358 x 220 canvas, scaled to fit.
    final sx = size.width / 358;
    final sy = size.height / 220;
    double x(double v) => (mirrored ? 358 - v : v) * sx;
    double y(double v) => v * sy;

    final done = Path()
      ..moveTo(x(44), y(170))
      ..cubicTo(x(104), y(170), x(124), y(112), x(180), y(112));
    final ahead = Path()
      ..moveTo(x(180), y(112))
      ..cubicTo(x(236), y(112), x(256), y(56), x(314), y(56));

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final metric in ahead.computeMetrics()) {
      _drawDashed(canvas, metric, stroke..color = AppColors.track);
    }
    canvas.drawPath(done, stroke..color = AppColors.primary);
  }

  void _drawDashed(Canvas canvas, PathMetric metric, Paint paint) {
    const dash = 8.0;
    const gap = 10.0;
    for (var d = 0.0; d < metric.length; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, d + dash), paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.mirrored != mirrored;
}

class _StartNode extends StatelessWidget {
  const _StartNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadii.nestedRadius,
                boxShadow: AppShadows.card,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.listening,
              ),
            ),
            PositionedDirectional(
              top: -5,
              end: -5,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: AppColors.onAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Listening',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PracticeNode extends StatelessWidget {
  const _PracticeNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.smd,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadii.nestedRadius,
            boxShadow: AppShadows.primaryButton,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.accent),
              ),
              Text(
                'Daily practice',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.track, width: 3),
          ),
        ),
      ],
    );
  }
}

class _GoalNode extends StatelessWidget {
  const _GoalNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 28),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.smd,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadii.buttonRadius,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, size: 18, color: AppColors.onAccent),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Your goal',
            style: AppTextStyles.labelLg.copyWith(color: AppColors.onAccent),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: AppTextStyles.labelSm.copyWith(letterSpacing: 0)),
        ],
      ),
    );
  }
}
