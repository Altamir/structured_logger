import 'validation_exception.dart';

/// Sentinel value for filtering empty/null device or property values.
class FilterConstants {
  static const emptySentinel = '__empty__';
}

/// Validates JSON property keys used in dynamic SQL paths.
class PropertyKeyValidator {
  static final RegExp _pattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_.-]*$');

  static void validate(String? key) {
    if (key == null || key.isEmpty) return;
    if (!_pattern.hasMatch(key)) {
      throw ValidationException(
        'Invalid property key: must match [A-Za-z_][A-Za-z0-9_.-]*',
      );
    }
  }

  static bool isValid(String key) => _pattern.hasMatch(key);

  /// SQLite JSON path for flat CLEF property keys in [json_extract].
  ///
  /// Dotted Serilog keys (e.g. `Source.Context`) must be quoted or SQLite
  /// treats `.` as a nested path separator.
  static String jsonExtractPath(String key) {
    validate(key);
    return '\$."$key"';
  }
}