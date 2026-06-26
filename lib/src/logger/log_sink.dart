import 'package:structured_logger/src/logger/log_model.dart';

/// Destination that receives structured log events from [StructureLogger].
abstract class LogSink {
  /// Writes a single [event] to this sink's output.
  Future<void> write(LogModel event);
}