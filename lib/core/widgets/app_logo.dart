import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// The Bandwise mark on a white rounded tile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  /// Tile size; the mark fills it with proportional padding.
  final double size;

  static const assetPath = 'assets/logo.svg';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bandwise logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsetsDirectional.all(size * 0.15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.card,
        ),
        child: SvgPicture.asset(assetPath, excludeFromSemantics: true),
      ),
    );
  }
}
