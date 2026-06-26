/// Structured log event passed to [LogSink.write].
class LogModel {
  /// ISO-8601 timestamp (`@t` in CLEF).
  String t;

  /// Message template with `{placeholders}` (`@mt` in CLEF).
  String mt;

  /// Log level name (`@l` in CLEF).
  String level;

  /// Structured properties bound to the message template.
  Map<String, dynamic>? data;

  /// Creates a log event. [t] defaults to the current time when empty.
  LogModel({
    required this.mt,
    this.level = "debug",
    this.data,
    this.t = "",
  }) {
    if (t.isEmpty) t = DateTime.now().toIso8601String();
  }

  /// Serializes this event to a map with CLEF-style keys.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '@t': t,
      '@mt': mt,
      '@l': level,
      'data': data,
    };
  }

  /// Builds a [LogModel] from a map produced by [toMap].
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      t: map['@t'],
      mt: map['@mt'],
      level: map['@l'],
      data: map['data'],
    );
  }
}