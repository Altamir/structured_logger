import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../models/filter_constants.dart';
import '../models/group_result.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
import 'schema.dart';

/// Storage access layer for log events.
class LogRepository {
  final Database _db;
  final int maxRows;

  LogRepository(this._db, {required this.maxRows});

  Future<void> ensureSchema() async {
    _db.execute(createAppLogsTable);
    for (final statement in createIndexes.split(';')) {
      final trimmed = statement.trim();
      if (trimmed.isNotEmpty) {
        _db.execute(trimmed);
      }
    }
  }

  Future<LogEntry> insert(LogEntry entry) async {
    return _withRetry(() {
      _db.execute('BEGIN IMMEDIATE');
      try {
        final stmt = _db.prepare('''
INSERT INTO app_logs (
  timestamp, level, message_template, rendered_message,
  exception, event_id, device_id, properties
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''');
        try {
          stmt.execute([
            entry.timestamp,
            entry.level,
            entry.messageTemplate,
            entry.renderedMessage,
            entry.exception,
            entry.eventId,
            entry.deviceId,
            jsonEncode(entry.properties),
          ]);
        } finally {
          stmt.dispose();
        }

        final id = _db.lastInsertRowId;
        _rotate();
        _db.execute('COMMIT');

        return entry.copyWith(id: id);
      } catch (e) {
        _db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  Future<List<LogEntry>> insertAll(List<LogEntry> entries) async {
    if (entries.isEmpty) {
      return [];
    }

    return _withRetry(() {
      _db.execute('BEGIN IMMEDIATE');
      try {
        final stmt = _db.prepare('''
INSERT INTO app_logs (
  timestamp, level, message_template, rendered_message,
  exception, event_id, device_id, properties
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''');
        final saved = <LogEntry>[];
        try {
          for (final entry in entries) {
            stmt.execute([
              entry.timestamp,
              entry.level,
              entry.messageTemplate,
              entry.renderedMessage,
              entry.exception,
              entry.eventId,
              entry.deviceId,
              jsonEncode(entry.properties),
            ]);
            saved.add(entry.copyWith(id: _db.lastInsertRowId));
          }
        } finally {
          stmt.dispose();
        }

        _rotate();
        _db.execute('COMMIT');
        return saved;
      } catch (e) {
        _db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  void _rotate() {
    _db.execute('''
DELETE FROM app_logs WHERE id IN (
  SELECT id FROM app_logs
  ORDER BY timestamp ASC
  LIMIT MAX(0, (SELECT COUNT(*) FROM app_logs) - $maxRows)
)
''');
  }

  Future<QueryResult> query(
    LogFilter filter, {
    int limit = 100,
    int offset = 0,
  }) async {
    final (where, params) = filter.toSql();
    final total = await count(filter);

    final rows = _db.select('''
SELECT * FROM app_logs
WHERE $where
ORDER BY timestamp DESC
LIMIT ? OFFSET ?
''', [...params, limit, offset]);

    final events = rows.map(_rowToEntry).toList();
    return QueryResult(
      events: events,
      total: total,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<GroupResult>> group(
    LogFilter filter,
    GroupBy groupBy, {
    TimeBucket? bucket,
    String? propertyName,
  }) async {
    final (where, params) = filter.toSql();
    final String sql;
    final List<Object?> queryParams = List<Object?>.from(params);

    switch (groupBy) {
      case GroupBy.level:
        sql = '''
SELECT level AS key, COUNT(*) AS count
FROM app_logs WHERE $where
GROUP BY level ORDER BY count DESC LIMIT 100
''';
      case GroupBy.time:
        final fmt = bucket?.sqlFormat ?? TimeBucket.hour.sqlFormat;
        sql = '''
SELECT strftime('$fmt', timestamp) AS key, COUNT(*) AS count
FROM app_logs WHERE $where
GROUP BY key ORDER BY key LIMIT 100
''';
      case GroupBy.deviceId:
        sql = '''
SELECT COALESCE(device_id, '(empty)') AS key, COUNT(*) AS count
FROM app_logs WHERE $where
GROUP BY key ORDER BY count DESC LIMIT 100
''';
      case GroupBy.property:
        final prop = propertyName ?? 'Screen';
        final path = PropertyKeyValidator.jsonExtractPath(prop);
        sql = '''
SELECT COALESCE(json_extract(properties, '$path'), '(empty)') AS key,
       COUNT(*) AS count
FROM app_logs WHERE $where
GROUP BY key ORDER BY count DESC LIMIT 100
''';
    }

    final rows = _db.select(sql, queryParams);
    return rows
        .map(
          (row) => GroupResult(
            key: row['key']?.toString() ?? '(empty)',
            count: row['count'] as int,
          ),
        )
        .toList();
  }

  Future<int> delete(LogFilter filter) async {
    return _withRetry(() {
      final (where, params) = filter.toSql();
      _db.execute('BEGIN IMMEDIATE');
      try {
        final stmt = _db.prepare('DELETE FROM app_logs WHERE $where');
        try {
          stmt.execute(params);
        } finally {
          stmt.dispose();
        }
        final deleted = _db.updatedRows;
        _db.execute('COMMIT');
        return deleted;
      } catch (e) {
        _db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  Stream<LogEntry> export(LogFilter filter) async* {
    final (where, params) = filter.toSql();
    const pageSize = 500;
    var offset = 0;

    while (true) {
      final rows = _db.select('''
SELECT * FROM app_logs
WHERE $where
ORDER BY timestamp ASC, id ASC
LIMIT ? OFFSET ?
''', [...params, pageSize, offset]);

      if (rows.isEmpty) break;

      for (final row in rows) {
        yield _rowToEntry(row);
      }

      if (rows.length < pageSize) break;
      offset += pageSize;
    }
  }

  Future<int> count([LogFilter? filter]) async {
    final f = filter ?? const LogFilter();
    final (where, params) = f.toSql();
    final rows = _db.select(
      'SELECT COUNT(*) AS cnt FROM app_logs WHERE $where',
      params,
    );
    return rows.first['cnt'] as int;
  }

  int countSince(String sqliteInterval) {
    final rows = _db.select(
      "SELECT COUNT(*) AS cnt FROM app_logs WHERE timestamp >= datetime('now', ?)",
      [sqliteInterval],
    );
    return rows.first['cnt'] as int;
  }

  List<({String period, int count})> countByHour({String since = '-24 hours'}) {
    final rows = _db.select('''
SELECT strftime('%Y-%m-%dT%H:00:00Z', timestamp) AS period, COUNT(*) AS count
FROM app_logs
WHERE timestamp >= datetime('now', ?)
GROUP BY period
ORDER BY period ASC
''', [since]);
    return rows
        .map(
          (row) => (
            period: row['period']?.toString() ?? '',
            count: row['count'] as int,
          ),
        )
        .toList();
  }

  List<({String period, int count})> ingestPeaks({
    String since = '-24 hours',
    int limit = 10,
  }) {
    final rows = _db.select('''
SELECT strftime('%Y-%m-%dT%H:%M:00Z', timestamp) AS period, COUNT(*) AS count
FROM app_logs
WHERE timestamp >= datetime('now', ?)
GROUP BY period
ORDER BY count DESC, period DESC
LIMIT ?
''', [since, limit]);
    return rows
        .map(
          (row) => (
            period: row['period']?.toString() ?? '',
            count: row['count'] as int,
          ),
        )
        .toList();
  }

  static int dbFileSizeBytes(String dbPath) {
    if (dbPath == ':memory:') return 0;
    try {
      final file = File(dbPath);
      if (file.existsSync()) return file.lengthSync();
    } catch (_) {}
    return 0;
  }

  LogEntry _rowToEntry(Map<String, Object?> row) {
    return LogEntry.fromRow(row);
  }

  Future<T> _withRetry<T>(T Function() action) async {
    const delays = [50, 100, 200];
    Object? lastError;

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return action();
      } on SqliteException catch (e) {
        lastError = e;
        if (!_isBusy(e) || attempt == delays.length) {
          if (_isBusy(e)) {
            throw StorageBusyException();
          }
          if (_isDiskFull(e)) {
            throw StorageFullException();
          }
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: delays[attempt]));
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 28) {
          throw StorageFullException();
        }
        rethrow;
      }
    }

    throw lastError ?? StateError('retry failed');
  }

  bool _isBusy(SqliteException e) {
    return e.extendedResultCode == 5 || e.resultCode == 5;
  }

  bool _isDiskFull(SqliteException e) {
    return e.extendedResultCode == 13 || e.resultCode == 13;
  }

  void close() => _db.dispose();
}

class StorageBusyException implements Exception {}

class StorageFullException implements Exception {}