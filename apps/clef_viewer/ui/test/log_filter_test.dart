import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogFilter.copyWith', () {
    const original = LogFilter(
      deviceId: 'my-app',
      properties: ['Screen=Home'],
      search: 'timeout',
    );

    test('clears deviceId while preserving other fields', () {
      final updated = original.copyWith(deviceId: null);
      expect(updated.deviceId, isNull);
      expect(updated.properties, ['Screen=Home']);
      expect(updated.search, 'timeout');
    });

    test('clears properties and search', () {
      final cleared = original.copyWith(properties: [], search: null);
      expect(cleared.properties, isEmpty);
      expect(cleared.search, isNull);
    });

    test('clears from and to dates', () {
      final withDates = LogFilter(
        from: DateTime.utc(2024, 1, 1),
        to: DateTime.utc(2024, 1, 2),
        deviceId: 'x',
      );
      final cleared = withDates.copyWith(from: null, to: null);
      expect(cleared.from, isNull);
      expect(cleared.to, isNull);
      expect(cleared.deviceId, 'x');
    });

    test('updates levels without clearing other fields', () {
      final updated = original.copyWith(levels: ['error']);
      expect(updated.levels, ['error']);
      expect(updated.deviceId, 'my-app');
    });
  });

  group('LogFilter.matches', () {
    test('requires all properties when multiple are set', () {
      const filter = LogFilter(
        properties: ['UserId=42', 'Screen=Home'],
      );
      const matching = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'UserId': 42, 'Screen': 'Home'},
      );
      const partial = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'UserId': 42},
      );

      expect(filter.matches(matching), isTrue);
      expect(filter.matches(partial), isFalse);
    });
  });

  group('LogFilter.toQueryParams', () {
    test('search matches properties JSON and device id', () {
      const filter = LogFilter(search: 'home');
      const byProperty = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'Screen': 'Home'},
      );
      const byDevice = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        deviceId: 'device-home',
      );

      expect(filter.matches(byProperty), isTrue);
      expect(filter.matches(byDevice), isTrue);
    });

    test('encodes multiple properties with semicolon', () {
      const filter = LogFilter(
        properties: ['UserId=42', 'Screen=Home'],
      );
      expect(filter.toQueryParams()['property'], 'UserId=42;Screen=Home');
    });
  });
}