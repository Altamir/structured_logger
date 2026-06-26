import 'dart:convert';

import '../models/log_entry.dart';

/// Thrown when CLEF payload cannot be parsed.
class ClefParseException implements Exception {
  final String message;
  ClefParseException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a single event exceeds [maxEventBytes].
class PayloadTooLargeException implements Exception {
  final int size;
  final int maxBytes;
  PayloadTooLargeException(this.size, this.maxBytes);

  @override
  String toString() => 'Event size $size exceeds limit $maxBytes';
}

/// Thrown when an NDJSON batch exceeds configured limits.
class BatchLimitExceededException implements Exception {
  final String message;
  final int limit;
  BatchLimitExceededException(this.message, this.limit);

  @override
  String toString() => message;
}

/// Converts CLEF JSON payloads into [LogEntry] instances.
class ClefParser {
  static const reservedColumnKeys = {
    '@t',
    '@l',
    '@mt',
    '@m',
    '@x',
    '@i',
    'DeviceIdentifier',
  };

  final int maxEventBytes;

  ClefParser({required this.maxEventBytes});

  LogEntry parseObject(Map<String, dynamic> json) {
    _checkSize(json);

    final timestamp = json['@t'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final level = json['@l'] as String? ?? 'information';

    final properties = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!reservedColumnKeys.contains(entry.key)) {
        properties[entry.key] = entry.value;
      }
    }

    return LogEntry(
      timestamp: timestamp,
      level: level,
      messageTemplate: json['@mt'] as String?,
      renderedMessage: json['@m'] as String?,
      exception: json['@x'] as String?,
      eventId: json['@i'] as String?,
      deviceId: json['DeviceIdentifier'] as String?,
      properties: properties,
    );
  }

  LogEntry parseJsonString(String body) {
    _checkRawSize(body);
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw ClefParseException('Expected JSON object');
      }
      return parseObject(decoded);
    } on ClefParseException {
      rethrow;
    } on PayloadTooLargeException {
      rethrow;
    } catch (_) {
      throw ClefParseException('Request body is not valid JSON');
    }
  }

  List<LogEntry> parseNdjson(String body) {
    final lines = body.split('\n');
    final entries = <LogEntry>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic>) {
          throw ClefParseException('Line ${i + 1}: expected JSON object');
        }
        entries.add(parseObject(decoded));
      } on ClefParseException {
        rethrow;
      } on PayloadTooLargeException {
        rethrow;
      } catch (_) {
        throw ClefParseException('Line ${i + 1}: invalid JSON');
      }
    }

    return entries;
  }

  void _checkRawSize(String body) {
    final bytes = utf8.encode(body).length;
    if (bytes > maxEventBytes) {
      throw PayloadTooLargeException(bytes, maxEventBytes);
    }
  }

  void _checkSize(Map<String, dynamic> json) {
    final bytes = utf8.encode(jsonEncode(json)).length;
    if (bytes > maxEventBytes) {
      throw PayloadTooLargeException(bytes, maxEventBytes);
    }
  }
}