/// Codec for multiple property filters in one query param (AND).
abstract final class PropertyFilterCodec {
  static const separator = ';';

  /// Each entry is `Key=value`.
  static List<String> parseField(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    return text
        .split(separator)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part.contains('='))
        .toList();
  }

  static String encodeField(List<String> filters) {
    if (filters.isEmpty) return '';
    return filters.join(separator);
  }

  /// Replaces an existing filter with the same key, or appends.
  static List<String> upsert(List<String> current, String keyValueParam) {
    final eq = keyValueParam.indexOf('=');
    if (eq <= 0) return current;
    final key = keyValueParam.substring(0, eq);
    final next = current
        .where((p) {
          final i = p.indexOf('=');
          return i <= 0 || p.substring(0, i) != key;
        })
        .toList();
    next.add(keyValueParam);
    return next;
  }

  static List<String> removeKey(List<String> current, String key) {
    return current
        .where((p) {
          final i = p.indexOf('=');
          return i <= 0 || p.substring(0, i) != key;
        })
        .toList();
  }

  static String? keyOf(String keyValueParam) {
    final eq = keyValueParam.indexOf('=');
    if (eq <= 0) return null;
    return keyValueParam.substring(0, eq);
  }
}