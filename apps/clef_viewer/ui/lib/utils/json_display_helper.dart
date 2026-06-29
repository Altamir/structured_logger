import 'dart:convert';

abstract final class JsonDisplayHelper {
  static const previewMaxChars = 400;
  static const previewMaxLines = 6;

  static final _prettyEncoder = const JsonEncoder.withIndent('  ');

  static bool isStructuredJsonValue(dynamic value) {
    if (value is Map || value is List) return true;
    if (value is! String) return false;
    return _tryParseJsonString(value) != null;
  }

  static String toPrettyJson(dynamic value) {
    final parsed = _normalizeForEncoding(value);
    if (parsed == null) return value.toString();
    return _prettyEncoder.convert(parsed);
  }

  static bool exceedsPreviewLimit(String text) {
    if (text.length > previewMaxChars) return true;
    return text.split('\n').length > previewMaxLines;
  }

  static String previewText(String text) {
    if (!exceedsPreviewLimit(text)) return text;

    final lines = text.split('\n');
    var truncated = lines.length > previewMaxLines
        ? lines.take(previewMaxLines).join('\n')
        : text;

    if (truncated.length > previewMaxChars) {
      truncated = truncated.substring(0, previewMaxChars);
    }

    return '$truncated…';
  }

  static dynamic _tryParseJsonString(String value) {
    final trimmed = value.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  static dynamic _normalizeForEncoding(dynamic value) {
    if (value is Map || value is List) return value;
    if (value is String) return _tryParseJsonString(value);
    return null;
  }
}