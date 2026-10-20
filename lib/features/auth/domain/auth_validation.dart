/// Form checks for the auth screens. Rule-based, run on the device.
library;

/// Minimum password length (Supabase is configured to match; see README).
const minPasswordLength = 8;

/// How strong a password looks.
enum PasswordStrength {
  tooShort('Too short', 0),
  weak('Weak password', 1),
  fair('Fair password', 2),
  strong('Strong password', 3);

  const PasswordStrength(this.label, this.level);

  final String label;

  /// 0–3, for the meter.
  final int level;

  /// Strong enough to sign up with.
  bool get acceptable => level >= fair.level;
}

/// [minPasswordLength]+ characters with letters and numbers is fair; adding
/// length (12+) or mixed case and a symbol makes it strong.
PasswordStrength passwordStrength(String password) {
  if (password.length < minPasswordLength) return PasswordStrength.tooShort;
  final letters = RegExp('[A-Za-z]').hasMatch(password);
  final digits = RegExp('[0-9]').hasMatch(password);
  if (!letters || !digits) return PasswordStrength.weak;
  final mixedCase =
      RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password);
  final symbol = RegExp('[^A-Za-z0-9]').hasMatch(password);
  final extras = [password.length >= 12, mixedCase, symbol].where((e) => e);
  return extras.length >= 2 ? PasswordStrength.strong : PasswordStrength.fair;
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Null when [email] looks valid; otherwise what to fix.
String? validateEmail(String email) {
  final value = email.trim();
  if (value.isEmpty) return 'Enter your email address.';
  if (!_email.hasMatch(value)) {
    return 'Please enter a valid email address (e.g. name@example.com).';
  }
  return null;
}

/// Null when [name] is usable.
String? validateName(String name) {
  final value = name.trim();
  if (value.isEmpty) return 'Enter your name.';
  if (value.length > 60) return 'Use 60 characters or fewer.';
  return null;
}

/// Null when [password] is strong enough for a new account.
String? validateNewPassword(String password) => switch (passwordStrength(
  password,
)) {
  PasswordStrength.tooShort => 'Use at least $minPasswordLength characters.',
  PasswordStrength.weak => 'Use both letters and numbers.',
  _ => null,
};

/// Null when [code] is six digits.
String? validateResetCode(String code) =>
    RegExp(r'^\d{6}$').hasMatch(code.trim())
    ? null
    : 'Enter the 6-digit code from the email.';
