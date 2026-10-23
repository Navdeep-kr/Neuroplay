/// Common input validators for form fields.
abstract final class Validators {
  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  /// Returns an error message if [value] is not a valid email, or null if valid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  /// Returns an error message if [value] is not a valid password, or null.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Returns an error message if [value] is empty, or null if valid.
  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  /// Returns an error message if [value] exceeds [maxLength], or null.
  static String? maxLength(
    String? value,
    int maxLength, [
    String field = 'This field',
  ]) {
    if (value != null && value.length > maxLength) {
      return '$field must be at most $maxLength characters';
    }
    return null;
  }
}
