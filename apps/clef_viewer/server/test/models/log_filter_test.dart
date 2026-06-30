import 'package:clef_viewer_server/models/filter_constants.dart';
import 'package:clef_viewer_server/models/log_entry.dart';
import 'package:clef_viewer_server/models/log_filter.dart';
import 'package:clef_viewer_server/models/property_filter.dart';
import 'package:test/test.dart';

void main() {
  group('LogFilter', () {
    test('builds SQL with parameters safely', () {
      final filter = LogFilter.fromQueryParams({
        'from': '2024-01-01T00:00:00Z',
        'to': '2024-01-02T00:00:00Z',
        'levels': 'error,warning',
        'device_id': 'dev-1',
        'search': 'timeout',
      });

      final (where, params) = filter.toSql();
      expect(where, contains('timestamp >='));
      expect(where, contains('level IN'));
      expect(where, contains('device_id = ?'));
      expect(where, contains('LIKE ?'));
      expect(params, contains('dev-1'));
      expect(params, contains('error'));
      expect(params, contains('warning'));
    });

    test('validates from <= to', () {
      final filter = LogFilter.fromQueryParams({
        'from': '2024-02-01T00:00:00Z',
        'to': '2024-01-01T00:00:00Z',
      });

      expect(() => filter.validate(), throwsA(isA<ValidationException>()));
    });

    test('accepts hyphenated and dotted property keys', () {
      final filter = LogFilter.fromQueryParams({
        'property': 'request-id=abc',
      });
      expect(() => filter.validate(), returnsNormally);
      final (where, _) = filter.toSql();
      expect(where, contains(r'$."request-id"'));
    });

    test('builds quoted json_extract path for dotted property keys', () {
      final filter = LogFilter.fromQueryParams({
        'property': 'Source.Context=my-app',
      });
      filter.validate();
      final (where, params) = filter.toSql();
      expect(where,
          contains(r'''json_extract(properties, '$."Source.Context"')'''));
      expect(params, contains('my-app'));
    });

    test('rejects malicious property keys', () {
      final filter = LogFilter.fromQueryParams({
        'property': "x') OR 1=1 --=value",
      });

      expect(() => filter.validate(), throwsA(isA<ValidationException>()));
      expect(() => filter.toSql(), throwsA(isA<ValidationException>()));
    });

    test('filters empty device via sentinel', () {
      final filter = LogFilter.fromQueryParams({
        'device_id': FilterConstants.emptySentinel,
      });
      filter.validate();
      final (where, params) = filter.toSql();
      expect(where, contains('device_id IS NULL'));
      expect(params, isEmpty);
    });

    test('filters empty property via sentinel', () {
      final filter = LogFilter.fromQueryParams({
        'property': 'Screen=${FilterConstants.emptySentinel}',
      });
      filter.validate();
      final (where, params) = filter.toSql();
      expect(where, contains('json_extract(properties'));
      expect(where, contains('IS NULL'));
      expect(params, isEmpty);
    });

    test('parses multiple properties as AND filter', () {
      final filter = LogFilter.fromQueryParams({
        'property': 'UserId=42;Screen=Home',
      });
      filter.validate();
      final (where, params) = filter.toSql();
      expect(where, contains('json_extract'));
      expect(where.split('json_extract').length, 3);
      expect(params, contains('42'));
      expect(params, contains('Home'));
    });

    test('matches numeric property as string', () {
      const filter = LogFilter(
        properties: [PropertyFilter(key: 'UserId', value: '42')],
      );
      const entry = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'UserId': 42},
      );

      expect(filter.matches(entry), isTrue);
    });

    test('matches all properties when multiple are set', () {
      const filter = LogFilter(
        properties: [
          PropertyFilter(key: 'UserId', value: '42'),
          PropertyFilter(key: 'Screen', value: 'Home'),
        ],
      );
      const matching = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'UserId': 42, 'Screen': 'Home'},
      );
      const partial = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'UserId': 42, 'Screen': 'Other'},
      );

      expect(filter.matches(matching), isTrue);
      expect(filter.matches(partial), isFalse);
    });

    test('matches dotted Serilog property key client-side', () {
      const filter = LogFilter(
        properties: [PropertyFilter(key: 'Source.Context', value: 'my-app')],
      );
      const matching = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'Source.Context': 'my-app'},
      );
      const other = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'Source.Context': 'other-app'},
      );

      expect(filter.matches(matching), isTrue);
      expect(filter.matches(other), isFalse);
    });

    test('matches entries client-side', () {
      const filter = LogFilter(levels: ['error'], search: 'fail');
      const entry = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'error',
        messageTemplate: 'Request fail',
      );

      expect(filter.matches(entry), isTrue);
    });

    test('search matches properties JSON and device_id', () {
      const filter = LogFilter(search: 'home');
      const byProperty = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        properties: {'Screen': 'Home'},
      );
      const byDevice = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        deviceId: 'device-home-1',
      );
      const noMatch = LogEntry(
        timestamp: '2024-01-01T00:00:00Z',
        level: 'info',
        messageTemplate: 'other',
      );

      expect(filter.matches(byProperty), isTrue);
      expect(filter.matches(byDevice), isTrue);
      expect(filter.matches(noMatch), isFalse);

      final (where, params) = filter.toSql();
      expect(where, contains('LOWER(properties) LIKE ?'));
      expect(where, contains('LOWER(device_id) LIKE ?'));
      expect(params, everyElement('%home%'));
    });
  });
}
