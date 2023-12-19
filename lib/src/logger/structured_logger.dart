import 'package:structured_logger/src/logger/log_level.dart';
import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

class StructureLogger {
  final List<LogSink> _sinks = [];

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

  void addSink(LogSink sink) {
    _sinks.add(sink);
  }

  void removeSink(LogSink sink) {
    _sinks.remove(sink);
  }
}
