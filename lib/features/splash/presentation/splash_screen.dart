import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../onboarding/presentation/onboarding_navigation.dart';

/// Brand screen shown at launch while saved state loads.
///
/// Stays up for at least [minDuration], or longer if loading takes longer,
/// then resumes onboarding where the user left off (or opens Home).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.minDuration = defaultMinDuration});

  static const defaultMinDuration = Duration(milliseconds: 1500);

  final Duration minDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startUp();
  }

  Future<void> _startUp() async {
    final (_, onboarding) = await (
      Future<void>.delayed(widget.minDuration),
      ref.read(onboardingControllerProvider.future),
    ).wait;
    if (!mounted) return;
    context.go(
      onboarding.completed ? AppRoutes.home : onboardingPath(onboarding.step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(
                header: true,
                child: Text(
                  'Bandwise',
                  style: AppTextStyles.headlineXl.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Small steps. Stronger English.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppPill(
                label: 'IELTS Academic prep',
                icon: Icons.circle,
                iconColor: AppColors.accent,
                background: AppColors.card,
                foreground: AppColors.textMuted,
              ),
              const Spacer(),
              Text(
                'Independent IELTS Academic prep',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
