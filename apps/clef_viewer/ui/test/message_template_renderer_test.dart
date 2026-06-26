import 'package:clef_viewer_ui/utils/message_template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageTemplateRenderer', () {
    test('substitutes simple placeholder', () {
      final segments = MessageTemplateRenderer.renderTemplate(
        'Hello {name}',
        {'name': 'Alice'},
      );
      expect(segments, isNotNull);
      expect(segments!.map((s) => s.text).join(), 'Hello Alice');
      expect(segments[1].kind, DisplaySegmentKind.substituted);
    });

    test('resolves dotted key', () {
      final plain = MessageTemplateRenderer.renderPlain(
        'Context: {Source.Context}',
        {'Source.Context': 'App'},
      );
      expect(plain, 'Context: App');
    });

    test('escapes double braces', () {
      final plain = MessageTemplateRenderer.renderPlain(
        'Value is {{literal}} here',
        {},
      );
      expect(plain, 'Value is {literal} here');
    });

    test('missing placeholder uses missing kind', () {
      final segments = MessageTemplateRenderer.renderTemplate(
        'Hello {name}',
        {},
      );
      expect(segments![1].text, '{name}');
      expect(segments[1].kind, DisplaySegmentKind.missing);
    });

    test('null value is missing', () {
      final segments = MessageTemplateRenderer.renderTemplate(
        'Hello {name}',
        {'name': null},
      );
      expect(segments![1].kind, DisplaySegmentKind.missing);
    });

    test('formats object as compact json', () {
      final value = MessageTemplateRenderer.formatPropertyValue({'a': 1});
      expect(value, '{"a":1}');
    });

    test('malformed brace is plain text', () {
      final plain = MessageTemplateRenderer.renderPlain('unclosed {', {});
      expect(plain, 'unclosed {');
    });

    test('unclosed double-brace escape is plain text', () {
      final plain = MessageTemplateRenderer.renderPlain('before {{unclosed', {});
      expect(plain, 'before {{unclosed');
    });
  });
}