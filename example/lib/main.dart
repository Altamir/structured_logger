import 'package:flutter/widgets.dart';
import 'package:structured_logger/structured_logger.dart';

/// Minimal example: log to the console and the Dart developer log.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = StructureLogger();
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());

  await logger.log(
    'Welcome {name}, your level is {level}',
    level: LogLevel.info,
    data: {'name': 'John Doe', 'level': 12},
  );
}