import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

/// Opens (or creates) the SQLite database and applies schema.
Database openDatabase(String path) {
  final db = sqlite3.open(path);
  db.execute(createAppLogsTable);
  for (final statement in createIndexes.split(';')) {
    final trimmed = statement.trim();
    if (trimmed.isNotEmpty) {
      db.execute(trimmed);
    }
  }
  return db;
}

/// In-memory database for tests.
Database openMemoryDatabase() {
  final db = sqlite3.openInMemory();
  db.execute(createAppLogsTable);
  for (final statement in createIndexes.split(';')) {
    final trimmed = statement.trim();
    if (trimmed.isNotEmpty) {
      db.execute(trimmed);
    }
  }
  return db;
}