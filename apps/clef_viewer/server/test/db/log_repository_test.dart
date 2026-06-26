import 'package:clef_viewer_server/db/database.dart';
import 'package:clef_viewer_server/models/filter_constants.dart';
import 'package:clef_viewer_server/db/log_repository.dart';
import 'package:clef_viewer_server/models/group_result.dart';
import 'package:clef_viewer_server/models/log_entry.dart';
import 'package:clef_viewer_server/models/log_filter.dart';
import 'package:test/test.dart';

void main() {
  late LogRepository repository;

  setUp(() {
    final db = openMemoryDatabase();
    repository = LogRepository(db, maxRows: 3);
  });

  LogEntry entry({
    required String ts,
    String level = 'info',
    String? deviceId,
    Map<String, dynamic> properties = const {},
  }) {
    return LogEntry(
      timestamp: ts,
      level: level,
      messageTemplate: 'msg $ts',
      deviceId: deviceId,
      properties: properties,
    );
  }

  test('insert and query events', () async {
    await repository.insert(
      entry(ts: '2024-01-01T00:00:01Z', level: 'info'),
    );
    await repository.insert(
      entry(ts: '2024-01-01T00:00:02Z', level: 'error'),
    );

    final result = await repository.query(const LogFilter(), limit: 10);
    expect(result.total, 2);
    expect(result.events.first.level, 'error');
  });

  test('FIFO rotation removes oldest rows', () async {
    await repository.insert(entry(ts: '2024-01-01T00:00:01Z'));
    await repository.insert(entry(ts: '2024-01-01T00:00:02Z'));
    await repository.insert(entry(ts: '2024-01-01T00:00:03Z'));
    await repository.insert(entry(ts: '2024-01-01T00:00:04Z'));

    final count = await repository.count();
    expect(count, 3);

    final result = await repository.query(const LogFilter(), limit: 10);
    final timestamps = result.events.map((e) => e.timestamp).toList();
    expect(timestamps, isNot(contains('2024-01-01T00:00:01Z')));
  });

  test('filters numeric property values as text', () async {
    await repository.insert(
      entry(ts: '2024-01-01T00:00:01Z', properties: {'UserId': 42}),
    );
    await repository.insert(
      entry(ts: '2024-01-01T00:00:02Z', properties: {'UserId': 99}),
    );

    final filter = LogFilter.fromQueryParams({'property': 'UserId=42'});
    final result = await repository.query(filter);
    expect(result.total, 1);
  });

  test('filters by multiple properties with AND', () async {
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:01Z',
        properties: {'UserId': '42', 'Screen': 'Home'},
      ),
    );
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:02Z',
        properties: {'UserId': '42', 'Screen': 'Other'},
      ),
    );

    final filter = LogFilter.fromQueryParams({
      'property': 'UserId=42;Screen=Home',
    });
    final result = await repository.query(filter);
    expect(result.total, 1);
  });

  test('filters by property key=value', () async {
    await repository.insert(
      entry(ts: '2024-01-01T00:00:01Z', properties: {'UserId': '42'}),
    );
    await repository.insert(
      entry(ts: '2024-01-01T00:00:02Z', properties: {'UserId': '99'}),
    );

    final filter = LogFilter.fromQueryParams({'property': 'UserId=42'});
    final result = await repository.query(filter);
    expect(result.total, 1);
    expect(result.events.first.properties['UserId'], '42');
  });

  test('groups by level', () async {
    await repository.insert(entry(ts: '2024-01-01T00:00:01Z', level: 'error'));
    await repository.insert(entry(ts: '2024-01-01T00:00:02Z', level: 'info'));
    await repository.insert(entry(ts: '2024-01-01T00:00:03Z', level: 'info'));

    final groups = await repository.group(const LogFilter(), GroupBy.level);
    final errorGroup = groups.firstWhere((g) => g.key == 'error');
    expect(errorGroup.count, 1);
  });

  test('filters empty device_id via sentinel', () async {
    await repository.insert(entry(ts: '2024-01-01T00:00:01Z'));
    await repository.insert(
      entry(ts: '2024-01-01T00:00:02Z', deviceId: 'dev-1'),
    );

    final filter = LogFilter.fromQueryParams({
      'device_id': FilterConstants.emptySentinel,
    });
    final result = await repository.query(filter);
    expect(result.total, 1);
    expect(result.events.first.deviceId, isNull);
  });

  test('filters by dotted Serilog property key', () async {
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:01Z',
        properties: {'Source.Context': 'my-app'},
      ),
    );
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:02Z',
        properties: {'Source.Context': 'other-app'},
      ),
    );

    final filter = LogFilter.fromQueryParams({
      'property': 'Source.Context=my-app',
    });
    final result = await repository.query(filter);
    expect(result.total, 1);
    expect(result.events.first.properties['Source.Context'], 'my-app');
  });

  test('groups by dotted Serilog property key', () async {
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:01Z',
        properties: {'Source.Context': 'my-app'},
      ),
    );
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:02Z',
        properties: {'Source.Context': 'my-app'},
      ),
    );
    await repository.insert(
      entry(
        ts: '2024-01-01T00:00:03Z',
        properties: {'Source.Context': 'other-app'},
      ),
    );

    final groups = await repository.group(
      const LogFilter(),
      GroupBy.property,
      propertyName: 'Source.Context',
    );
    final myAppGroup = groups.firstWhere((g) => g.key == 'my-app');
    expect(myAppGroup.count, 2);
  });

  test('delete with filter', () async {
    await repository.insert(entry(ts: '2024-01-01T00:00:01Z', level: 'error'));
    await repository.insert(entry(ts: '2024-01-01T00:00:02Z', level: 'info'));

    final deleted = await repository.delete(
      const LogFilter(levels: ['error']),
    );
    expect(deleted, 1);
    expect(await repository.count(), 1);
  });
}