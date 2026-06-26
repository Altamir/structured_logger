import 'package:structured_logger/src/logger/log_level.dart';
import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

/// Central logger that fans out structured events to registered [LogSink]s.
class StructureLogger {
  /// Creates an empty logger with no sinks registered yet.
  StructureLogger();

  final List<LogSink> _sinks = [];

  /// Emits a structured log with an optional [level] and [data] properties.
  Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) async {
    LogModel logModel = LogModel(
      mt: message,
      level: level.sValue,
      data: data,
    );
    for (LogSink sink in _sinks) {
      //TODO: No futuro apenas vai enviar salvar, um service em background deve processar os envios
      await sink.write(logModel);
    }
  }

  /// Registers a sink that will receive every subsequent log event.
  void addSink(LogSink sink) {
    _sinks.add(sink);
  }

  /// Stops delivering log events to [sink].
  void removeSink(LogSink sink) {
    _sinks.remove(sink);
  }
}