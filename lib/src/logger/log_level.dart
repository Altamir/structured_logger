/// Severity levels used when emitting logs through [StructureLogger].
enum LogLevel {
  /// Informational events.
  info,

  /// Potentially harmful situations.
  warning,

  /// Detailed diagnostic information.
  debug,

  /// Error events that may still allow the app to continue.
  error,

  /// Fine-grained tracing, more detailed than [debug].
  verbose,
}

/// String values for [LogLevel] used in serialized log output.
extension LogLevelExtension on LogLevel {
  /// Returns the level name stored in [LogModel.level].
  String get sValue => switch (this) {
        LogLevel.info => "info",
        LogLevel.warning => "warning",
        LogLevel.debug => "debug",
        LogLevel.error => "error",
        LogLevel.verbose => "verbose",
      };
}