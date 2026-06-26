import 'dart:io';

import 'package:clef_viewer_server/api/router.dart';
import 'package:clef_viewer_server/config.dart';
import 'package:clef_viewer_server/db/database.dart';
import 'package:clef_viewer_server/db/log_repository.dart';
import 'package:clef_viewer_server/stream/event_broadcaster.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final config = AppConfig.fromEnvironment();
  final db = openDatabase(config.dbPath);
  final repository = LogRepository(db, maxRows: config.maxRows);
  await repository.ensureSchema();

  final broadcaster = EventBroadcaster();
  final handler = createHandler(
    config: config,
    repository: repository,
    broadcaster: broadcaster,
  );

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  stdout.writeln(
    'CLEF Viewer server listening on http://localhost:${server.port}',
  );
}