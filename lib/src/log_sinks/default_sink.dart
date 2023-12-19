import 'dart:developer';

import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

class DefaultSink extends LogSink {
  @override
  Future<void> write(LogModel event) async {
    log(event.toMap().toString());
  }
}
