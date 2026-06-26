import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogFilter.copyWith', () {
    const original = LogFilter(
      from: null,
      to: null,
      levels: ['error', 'warning'],
      deviceId: 'my-app',
      property: 'Screen=Home',
      search: 'timeout',
    );

    test('clears deviceId while preserving other fields', () {
      final updated = original.copyWith(deviceId: null);
      expect(updated.deviceId, isNull);
      expect(updated.levels, ['error', 'warning']);
      expect(updated.property, 'Screen=Home');
      expect(updated.search, 'timeout');
    });

    test('clears property and search', () {
      final cleared = original.copyWith(property: null, search: null);
      expect(cleared.property, isNull);
      expect(cleared.search, isNull);
      expect(cleared.deviceId, 'my-app');
    });

    test('clears from and to dates', () {
      final from = DateTime.utc(2024, 1, 1);
      final to = DateTime.utc(2024, 1, 2);
      final filter = LogFilter(from: from, to: to);
      final cleared = filter.copyWith(from: null, to: null);
      expect(cleared.from, isNull);
      expect(cleared.to, isNull);
    });

    test('updates levels without clearing other fields', () {
      final updated = original.copyWith(levels: ['info']);
      expect(updated.levels, ['info']);
      expect(updated.deviceId, 'my-app');
    });
  });
}