import 'dart:async';

import 'package:test/test.dart';
import 'package:structured_logger/structured_logger.dart';

/// Local capture for core tests (mirrors interceptor test pattern).
class CaptureSink extends LogSink {
  final events = <LogModel>[];
  @override
  Future<void> write(LogModel event) async => events.add(event);
}

void main() {
  group('StructureLogger', () {
    test('should create an instance of StructureLogger', () async {
      final logger = StructureLogger();
      expect(logger, isA<StructureLogger>());
    });

    test('log emits to registered CaptureSink', () async {
      final cap = CaptureSink();
      final logger = StructureLogger()..addSink(cap);
      await logger.log('test {x}', level: LogLevel.info, data: {'x': 1});
      expect(cap.events, hasLength(1));
      expect(cap.events.first.mt, 'test {x}');
      expect(cap.events.first.level, 'info');
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

    test('LogModel roundtrip toMap/fromMap', () {
      final original = LogModel(
        mt: 'Hello {name}',
        level: 'info',
        data: {'name': 'World'},
      );
      final map = original.toMap();
      final restored = LogModel.fromMap(map);
      expect(restored.mt, original.mt);
      expect(restored.level, original.level);
      expect(restored.data, original.data);
      expect(restored.t, isNotEmpty);
    });

    test('LogModel.fromMap handles missing fields defensively', () {
      final m = LogModel.fromMap({'@mt': 'only mt'});
      expect(m.mt, 'only mt');
      expect(m.level, 'debug');
      expect(m.t, isNotEmpty);
      expect(m.data, isNull);
    });

    test('LogModel.fromMap throws on missing or empty mt', () {
      expect(() => LogModel.fromMap({'@t': 'now'}), throwsArgumentError);
      expect(() => LogModel.fromMap({'@mt': ''}), throwsArgumentError);
      expect(() => LogModel.fromMap({'@mt': null}), throwsArgumentError);
    });

    test('StructureLogger logs safely under sink mutation (uses snapshot)', () async {
      final logger = StructureLogger();
      final events = <LogModel>[];
      late LogSink mutatingSink;
      mutatingSink = _MutatingSink(logger, events);
      logger.addSink(mutatingSink);

      await logger.log('safe log');
      // mutation happened inside write, but snapshot prevented CME
      expect(events, hasLength(1));
    });

    test('re-exports CLEF constants from barrel for server consumers', () {
      // trivial guard that constants are exported and have expected values
      expect(CONTENT_TYPE_CLEF, 'application/vnd.serilog.clef');
      expect(SEQ_API_KEY, 'X-Seq-ApiKey');
      expect(ERROR_SEND_TO_SEQ, 'Error sending logs to Seq: ');
    });
  });
}

/// Helper sink that mutates the logger's sinks during write to test snapshot.
class _MutatingSink implements LogSink {
  final StructureLogger logger;
  final List<LogModel> events;
  _MutatingSink(this.logger, this.events);

  @override
  Future<void> write(LogModel event) async {
    events.add(event);
    // mutate during the awaited write
    logger.removeSink(this);
    logger.addSink(SimpleLineSink()); // harmless add
  }
}

