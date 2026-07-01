/// Converts Dart default [Object.toString] representations into JSON-friendly
/// structures, e.g. `CustomerAddress({id: 1, street: Main St})`.
abstract final class DartReprParser {
  static final _reprStart = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\(\{');
  static final _validKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
  static final _instanceOf = RegExp(r"^Instance of '[^']+'$");

  static dynamic normalizeValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), normalizeValue(item)),
      );
    }
    if (value is List) {
      return value.map(normalizeValue).toList();
    }
    if (value is String) {
      if (_instanceOf.hasMatch(value.trim())) return value;
      return tryParseDartRepr(value) ?? value;
    }
    return value;
  }

  static Map<String, dynamic>? tryParseDartRepr(String input) {
    final trimmed = input.trim();
    if (!_reprStart.hasMatch(trimmed)) return null;

    final openParen = trimmed.indexOf('(');
    if (openParen <= 0) return null;

    final typeName = trimmed.substring(0, openParen);
    if (trimmed.length < openParen + 2 || trimmed[openParen + 1] != '{') {
      return null;
    }

    final closeBrace = _findMatchingBrace(trimmed, openParen + 1);
    if (closeBrace == -1) return null;

    if (closeBrace + 1 >= trimmed.length || trimmed[closeBrace + 1] != ')') {
      return null;
    }

    final trailing = trimmed.substring(closeBrace + 2).trim();
    if (trailing.isNotEmpty) return null;

    final fieldsContent = trimmed.substring(openParen + 2, closeBrace);
    final fields = _parseFields(fieldsContent);
    if (fields == null) return null;

    return {'_type': typeName, ...fields};
  }

  static Map<String, dynamic>? _parseFields(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return {};

    final result = <String, dynamic>{};
    for (final field in _splitAtDepthZero(trimmed, ',')) {
      final fieldTrimmed = field.trim();
      if (fieldTrimmed.isEmpty) continue;

      final colonIndex = _findColonAtDepthZero(fieldTrimmed);
      if (colonIndex == -1) return null;

      final key = fieldTrimmed.substring(0, colonIndex).trim();
      if (!_validKey.hasMatch(key)) return null;

      final valueText = fieldTrimmed.substring(colonIndex + 1).trim();
      result[key] = _parseValue(valueText);
    }

    return result;
  }

  static dynamic _parseValue(String valueText) {
    if (valueText == 'null') return null;
    if (valueText == 'true') return true;
    if (valueText == 'false') return false;
    if (valueText.isEmpty) return '';

    final intValue = int.tryParse(valueText);
    if (intValue != null) return intValue;

    final doubleValue = double.tryParse(valueText);
    if (doubleValue != null) return doubleValue;

    final nested = tryParseDartRepr(valueText);
    if (nested != null) return nested;

    return valueText;
  }

  static int _findMatchingBrace(String input, int openIndex) {
    var depth = 0;
    for (var i = openIndex; i < input.length; i++) {
      final char = input[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static int _findColonAtDepthZero(String input) {
    var depth = 0;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '{' || char == '(') {
        depth++;
      } else if (char == '}' || char == ')') {
        depth--;
      } else if (char == ':' && depth == 0) {
        return i;
      }
    }
    return -1;
  }

  static List<String> _splitAtDepthZero(String input, String separator) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '{' || char == '(') {
        depth++;
      } else if (char == '}' || char == ')') {
        depth--;
      } else if (char == separator && depth == 0) {
        parts.add(input.substring(start, i));
        start = i + 1;
      }
    }

    parts.add(input.substring(start));
    return parts;
  }
}