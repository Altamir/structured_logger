import 'package:clef_viewer_ui/models/filter_constants.dart';
import 'package:clef_viewer_ui/utils/property_filter_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyFilterHelper', () {
    test('isFilterable for primitives', () {
      expect(PropertyFilterHelper.isFilterable('x'), isTrue);
      expect(PropertyFilterHelper.isFilterable(42), isTrue);
      expect(PropertyFilterHelper.isFilterable(true), isTrue);
      expect(PropertyFilterHelper.isFilterable({'a': 1}), isFalse);
      expect(PropertyFilterHelper.isFilterable([1]), isFalse);
      expect(PropertyFilterHelper.isFilterable(null), isTrue);
    });

    test('toFilterParam uses sentinel for null', () {
      expect(
        PropertyFilterHelper.toFilterParam('Key', null),
        'Key=${FilterConstants.emptySentinel}',
      );
      expect(PropertyFilterHelper.toFilterParam('UserId', 42), 'UserId=42');
    });

    test('displayValue formats values', () {
      expect(PropertyFilterHelper.displayValue(null), '(empty)');
      expect(PropertyFilterHelper.displayValue(42), '42');
      expect(PropertyFilterHelper.displayValue({'a': 1}), '{"a":1}');
    });
  });
}