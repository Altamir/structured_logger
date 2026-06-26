import 'dart:developer';

import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

/// Writes each log event to the Dart developer log via `dart:developer`.
class DefaultSink extends LogSink {
  /// Creates a [DefaultSink].
  DefaultSink();

  @override
  Future<void> write(LogModel event) async {
    log(event.toMap().toString());
  }
}
