/// Structured logging for Flutter with pluggable output sinks.
///
/// Use [StructureLogger] to emit structured log events and attach one or more
/// [LogSink] implementations such as [SimpleLineSink], [DefaultSink], or
/// [SinkSeq].
library structured_logger;

export 'package:structured_logger/src/logger/log_level.dart';
export 'package:structured_logger/src/logger/log_model.dart';
export 'package:structured_logger/src/logger/log_sink.dart';
export 'package:structured_logger/src/logger/structured_logger.dart';
export 'package:structured_logger/src/log_sinks/default_sink.dart';
export 'package:structured_logger/src/log_sinks/simple_line_sink.dart';
export 'package:structured_logger/src/log_sinks/sink_seq.dart';