import 'dart:convert';

enum DisplaySegmentKind { plain, substituted, missing }

class DisplayMessageSegment {
  final String text;
  final DisplaySegmentKind kind;

  const DisplayMessageSegment(this.text, this.kind);
}

class MessageTemplateRenderer {
  static final _placeholderPattern =
      RegExp(r'^\{([A-Za-z_][A-Za-z0-9_.-]*)\}');

  /// Returns segment list for [template], or null if [template] is empty.
  static List<DisplayMessageSegment>? renderTemplate(
    String template,
    Map<String, dynamic> properties,
  ) {
    if (template.isEmpty) return null;

    final segments = <DisplayMessageSegment>[];
    var i = 0;

    while (i < template.length) {
      if (i + 1 < template.length &&
          template[i] == '{' &&
          template[i + 1] == '{') {
        final close = template.indexOf('}}', i + 2);
        if (close != -1) {
          final literal = template.substring(i + 2, close);
          segments.add(
            DisplayMessageSegment('{$literal}', DisplaySegmentKind.plain),
          );
          i = close + 2;
          continue;
        }
      }

      if (template[i] == '{') {
        final rest = template.substring(i);
        final match = _placeholderPattern.matchAsPrefix(rest);
        if (match != null) {
          final key = match.group(1)!;
          if (properties.containsKey(key) && properties[key] != null) {
            segments.add(
              DisplayMessageSegment(
                formatPropertyValue(properties[key]),
                DisplaySegmentKind.substituted,
              ),
            );
          } else {
            segments.add(
              DisplayMessageSegment('{$key}', DisplaySegmentKind.missing),
            );
          }
          i += match.end;
          continue;
        }
      }

      final start = i;
      while (i < template.length && template[i] != '{') {
        i++;
      }
      if (i > start) {
        segments.add(
          DisplayMessageSegment(
            template.substring(start, i),
            DisplaySegmentKind.plain,
          ),
        );
      } else {
        segments.add(
          DisplayMessageSegment(template[i], DisplaySegmentKind.plain),
        );
        i++;
      }
    }

    return segments;
  }

  /// Plain text without styles — for copy and tests.
  static String renderPlain(String template, Map<String, dynamic> properties) {
    final segments = renderTemplate(template, properties);
    if (segments == null) return template;
    return segments.map((s) => s.text).join();
  }

  static String formatPropertyValue(dynamic value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }
}