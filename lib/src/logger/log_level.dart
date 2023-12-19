/// Level of the log
/// for filtering and importance
enum LogLevel {
  /// information level logging
  info,

  /// warning level logging
  warning,

  /// debug level logging
  debug,

  /// error level logging
  error,

  /// verbose level logging
  verbose,
}

extension LogLevelExtension on LogLevel {
  /// returns the string representation of the log level
  String get sValue => switch (this) {
        LogLevel.info => "info",
        LogLevel.warning => "warning",
        LogLevel.debug => "debug",
        LogLevel.error => "error",
        LogLevel.verbose => "verbose",
      };
}
