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
    if (t.isEmpty) t = DateTime.now().toUtc().toIso8601String();
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
  /// Defensive: provides defaults for missing fields to avoid runtime cast
  /// errors on partial/malformed input (public API).
  factory LogModel.fromMap(Map<String, dynamic> map) {
    final mt = map['@mt'] as String?;
    if (mt == null || mt.isEmpty) {
      throw ArgumentError.value(mt, '@mt', 'mt is required and non-empty');
    }
    return LogModel(
      t: (map['@t'] as String?) ?? '',
      mt: mt,
      level: (map['@l'] as String?) ?? 'debug',
      data: map['data'] as Map<String, dynamic>?,
    );
  }
}
