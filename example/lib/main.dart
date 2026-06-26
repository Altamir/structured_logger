import 'package:structured_logger/structured_logger.dart';

/// Pure Dart CLI example — run with `dart run lib/main.dart` from the
/// `example/` directory (no Flutter required).
Future<void> main() async {
  final logger = StructureLogger();
  logger.addSink(SimpleLineSink());
  logger.addSink(DefaultSink());
  logger.addSink(
    SinkSeq('http://localhost:5341', deviceIdentifier: 'debug-test'),
  );

  await logger.log(
    'Welcome {name}, your level is {level}',
    level: LogLevel.info,
    data: {'name': 'John Doe', 'level': 12},
  );
}