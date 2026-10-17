import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Home's top bar: avatar, wordmark and a notifications bell.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    required this.displayName,
    required this.onNotifications,
  });

  /// Null for a guest (or while loading): the avatar shows a person icon.
  final String? displayName;
  final VoidCallback onNotifications;

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
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.page,
              end: AppSpacing.xs,
            ),
            child: Row(
              children: [
                _Avatar(displayName: displayName),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Bandwise',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNotifications,
                  tooltip: 'Notifications',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.text,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                    highlightColor: AppColors.primaryTint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.displayName});

  final String? displayName;

  /// "Alex Morgan" -> "AM"; "Alex" -> "A".
  static String? initialsOf(String? name) {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2);
    if (words.isEmpty) return null;
    return words.map((w) => w.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(displayName);
    return Semantics(
      label: initials == null ? 'Guest' : displayName,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.track, width: 2),
        ),
        child: initials == null
            ? const Icon(
                Icons.person_rounded,
                size: 20,
                color: AppColors.primary,
              )
            : Text(
                initials,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
