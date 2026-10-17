import 'package:flutter/painting.dart';

/// Corner radius tokens.
abstract final class AppRadii {
  static const double card = 18;
  static const double button = 14;
  static const double input = 14;
  static const double nested = 12;
  static const double pill = 999;

  /// Top corners of chart bars.
  static const double bar = 6;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const buttonRadius = BorderRadius.all(Radius.circular(button));
  static const inputRadius = BorderRadius.all(Radius.circular(input));
  static const nestedRadius = BorderRadius.all(Radius.circular(nested));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
}
