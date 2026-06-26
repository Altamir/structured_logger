class LogEntry {
  final int? id;
  final String timestamp;
  final String level;
  final String? messageTemplate;
  final String? renderedMessage;
  final String? exception;
  final String? eventId;
  final String? deviceId;
  final Map<String, dynamic> properties;

  const LogEntry({
    this.id,
    required this.timestamp,
    required this.level,
    this.messageTemplate,
    this.renderedMessage,
    this.exception,
    this.eventId,
    this.deviceId,
    this.properties = const {},
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as int?,
      timestamp: json['timestamp'] as String,
      level: json['level'] as String,
      messageTemplate: json['messageTemplate'] as String?,
      renderedMessage: json['renderedMessage'] as String?,
      exception: json['exception'] as String?,
      eventId: json['eventId'] as String?,
      deviceId: json['deviceId'] as String?,
      properties: Map<String, dynamic>.from(
        (json['properties'] as Map<String, dynamic>? ?? {}),
      ),
    );
  }

  String get displayMessage =>
      renderedMessage ?? messageTemplate ?? exception ?? '(no message)';
}

class QueryResult {
  final List<LogEntry> events;
  final int total;
  final int limit;
  final int offset;

  const QueryResult({
    required this.events,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory QueryResult.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>;
    return QueryResult(
      events: eventsJson
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}

class GroupResult {
  final String key;
  final int count;

  const GroupResult({required this.key, required this.count});

  factory GroupResult.fromJson(Map<String, dynamic> json) {
    return GroupResult(
      key: json['key'] as String,
      count: json['count'] as int,
    );
  }
}