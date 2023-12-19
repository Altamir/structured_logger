import 'package:structured_logger/src/logger/log_model.dart';

abstract class LogSink {
  Future<void> write(LogModel event);
}
