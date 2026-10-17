import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. Overridden in tests to move time forward, e.g. to
/// simulate the app being in the background.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
