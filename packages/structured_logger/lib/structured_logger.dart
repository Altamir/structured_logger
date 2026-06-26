/// Structured logging for Dart with pluggable output sinks.
///
/// Use [StructureLogger] to emit structured log events and attach one or more
/// [LogSink] implementations such as [SimpleLineSink], [DefaultSink], or
/// [SinkSeq]. (Flutter is supported as a consumer.)
library structured_logger; // ignore: unnecessary_library_name

export 'package:structured_logger/src/logger/log_level.dart';
export 'package:structured_logger/src/logger/log_model.dart';
export 'package:structured_logger/src/logger/log_sink.dart';
export 'package:structured_logger/src/logger/structured_logger.dart';
export 'package:structured_logger/src/log_sinks/default_sink.dart';
export 'package:structured_logger/src/log_sinks/simple_line_sink.dart';
export 'package:structured_logger/src/log_sinks/sink_seq.dart';
export 'package:structured_logger/src/log_sinks/seq_constants.dart';
