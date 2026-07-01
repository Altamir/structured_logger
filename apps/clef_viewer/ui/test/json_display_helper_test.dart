import 'dart:convert';

import 'package:clef_viewer_ui/utils/json_display_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonDisplayHelper', () {
    test('isStructuredJsonValue detects Map, List and JSON strings', () {
      expect(JsonDisplayHelper.isStructuredJsonValue({'a': 1}), isTrue);
      expect(JsonDisplayHelper.isStructuredJsonValue([1, 2]), isTrue);
      expect(JsonDisplayHelper.isStructuredJsonValue('{"a":1}'), isTrue);
      expect(JsonDisplayHelper.isStructuredJsonValue('[1,2]'), isTrue);
      expect(JsonDisplayHelper.isStructuredJsonValue('hello'), isFalse);
      expect(JsonDisplayHelper.isStructuredJsonValue(42), isFalse);
    });

    test('toPrettyJson formats structured values', () {
      expect(
        JsonDisplayHelper.toPrettyJson({'a': 1}),
        '{\n  "a": 1\n}',
      );
      expect(
        JsonDisplayHelper.toPrettyJson('[1,2]'),
        '[\n  1,\n  2\n]',
      );
      expect(
        JsonDisplayHelper.toPrettyJson('{"b":2}'),
        '{\n  "b": 2\n}',
      );
      expect(JsonDisplayHelper.toPrettyJson('plain'), 'plain');
    });

    test('exceedsPreviewLimit uses char and line thresholds', () {
      expect(JsonDisplayHelper.exceedsPreviewLimit('short'), isFalse);
      expect(
        JsonDisplayHelper.exceedsPreviewLimit('a' * 401),
        isTrue,
      );
      expect(
        JsonDisplayHelper.exceedsPreviewLimit('line\n' * 7),
        isTrue,
      );
    });

    test('previewText truncates with ellipsis', () {
      final long = 'a' * 500;
      final preview = JsonDisplayHelper.previewText(long);
      expect(preview.endsWith('…'), isTrue);
      expect(preview.length, lessThanOrEqualTo(401));
    });

    test('toPrettyJson normalizes dart repr strings in lists', () {
      const address =
          'CustomerAddress({id: 1, principal: true, street: Main St, number: 10})';
      final pretty = JsonDisplayHelper.toPrettyJson({
        'addresses': [address],
      });

      final decoded = jsonDecode(pretty) as Map<String, dynamic>;
      final addresses = decoded['addresses'] as List<dynamic>;
      expect(addresses.first, isA<Map<String, dynamic>>());
      expect(addresses.first['street'], 'Main St');
      expect(pretty, contains('\n'));
    });
  });
}