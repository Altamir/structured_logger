import 'dart:convert';

/// Persisted log event entity (API/SSE DTO).
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

  LogEntry copyWith({
    int? id,
    String? timestamp,
    String? level,
    String? messageTemplate,
    String? renderedMessage,
    String? exception,
    String? eventId,
    String? deviceId,
    Map<String, dynamic>? properties,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      renderedMessage: renderedMessage ?? this.renderedMessage,
      exception: exception ?? this.exception,
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'timestamp': timestamp,
        'level': level,
        if (messageTemplate != null) 'messageTemplate': messageTemplate,
        if (renderedMessage != null) 'renderedMessage': renderedMessage,
        if (exception != null) 'exception': exception,
        if (eventId != null) 'eventId': eventId,
        if (deviceId != null) 'deviceId': deviceId,
        'properties': properties,
      };

  factory LogEntry.fromRow(Map<String, Object?> row) {
    final propsJson = row['properties'] as String? ?? '{}';
    return LogEntry(
      id: row['id'] as int?,
      timestamp: row['timestamp'] as String,
      level: row['level'] as String,
      messageTemplate: row['message_template'] as String?,
      renderedMessage: row['rendered_message'] as String?,
      exception: row['exception'] as String?,
      eventId: row['event_id'] as String?,
      deviceId: row['device_id'] as String?,
      properties: Map<String, dynamic>.from(
        jsonDecode(propsJson) as Map<String, dynamic>,
      ),
    );
  }
}

/// Paginated query result.
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

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
        'total': total,
        'limit': limit,
        'offset': offset,
      };
}