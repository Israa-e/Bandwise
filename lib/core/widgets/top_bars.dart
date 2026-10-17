import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'progress.dart';

const _barHeight = 64.0;

/// Background for custom top bars. Flat while the content under it is at
/// the top; shows a subtle shadow once content scrolls underneath, like
/// [AppBar.scrolledUnderElevation].
///
/// Listens to the nearest [Scaffold]'s scroll notifications, so it only
/// reacts when used as (part of) a [Scaffold.appBar].
class TopBarSurface extends StatefulWidget {
  const TopBarSurface({super.key, required this.child});

  final Widget child;

  @override
  State<TopBarSurface> createState() => _TopBarSurfaceState();
}

class _TopBarSurfaceState extends State<TopBarSurface> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        !defaultScrollNotificationPredicate(notification)) {
      return;
    }
    final metrics = notification.metrics;
    final scrolledUnder = switch (metrics.axisDirection) {
      AxisDirection.down => metrics.extentBefore > 0,
      AxisDirection.up => metrics.extentAfter > 0,
      // Horizontal lists (carousels, chip rows) don't affect the bar.
      AxisDirection.left || AxisDirection.right => _scrolledUnder,
    };
    if (scrolledUnder != _scrolledUnder) {
      setState(() => _scrolledUnder = scrolledUnder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: _scrolledUnder ? AppShadows.topBar : null,
      ),
      child: Material(type: MaterialType.transparency, child: widget.child),
    );
  }
}

/// Circular back button. The arrow icon mirrors automatically in RTL.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Go back',
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        highlightColor: AppColors.primaryTint,
      ),
    );
  }
}

/// Top bar for a tab or a screen inside one: an optional back button, a
/// title, and an optional trailing widget.
class TabTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TabTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = false,
  });

  final String title;
  final Widget? trailing;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: showBack ? AppSpacing.xs : AppSpacing.page,
              end: AppSpacing.page,
            ),
            child: Row(
              children: [
                if (showBack) ...[
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTextStyles.headlineMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for onboarding steps: back button, centered "Step X of Y" with a
/// segmented progress bar, and an optional trailing action (e.g. Skip).
class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingTopBar({
    super.key,
    required this.step,
    required this.totalSteps,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final bool showBack;

  /// Usually a ghost [AppButton] such as "Skip".
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: NavigationToolbar(
              leading: showBack ? AppBackButton(onPressed: onBack) : null,
              middle: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      'Step $step of $totalSteps',
                      style: AppTextStyles.tabular(AppTextStyles.labelMd),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedStepProgress(current: step, total: totalSteps),
                ],
              ),
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for auth screens: back button and an optional trailing action
/// (e.g. "Log in" on the sign-up screen). No title; the screen has its own.
class AuthTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthTopBar({
    super.key,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showBack) AppBackButton(onPressed: onBack),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
