import 'package:flutter_test/flutter_test.dart';
import 'package:structured_logger/structured_logger.dart';

void main() {
  group('StructureLogger', () {
    test('should create an instance of StructureLogger', () async {
      final logger = StructureLogger();
      expect(logger, isA<StructureLogger>());
    });

    test('SimpleLineSink', () async {
      final logger = StructureLogger();
      LogSink sink = SimpleLineSink();
      logger.addSink(sink);

      LogSink defaultlog = DefaultSink();
      logger.addSink(defaultlog);

      await logger.log(
        "Seja bem vindo {name}, seu nível é {level}",
        level: LogLevel.info,
        data: {"name": "John Doe", "level": 12},
      );
    });
  });
}
