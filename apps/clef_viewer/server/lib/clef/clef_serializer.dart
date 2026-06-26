import 'dart:convert';

import '../models/log_entry.dart';

/// Reconstructs CLEF JSON from persisted [LogEntry] rows.
class ClefSerializer {
  Map<String, dynamic> toClef(LogEntry entry) {
    final clef = <String, dynamic>{
      ...entry.properties,
      '@t': entry.timestamp,
      '@l': entry.level,
    };

    if (entry.messageTemplate != null) {
      clef['@mt'] = entry.messageTemplate;
    }
    if (entry.renderedMessage != null) {
      clef['@m'] = entry.renderedMessage;
    }
    if (entry.exception != null) {
      clef['@x'] = entry.exception;
    }
    if (entry.eventId != null) {
      clef['@i'] = entry.eventId;
    }
    if (entry.deviceId != null) {
      clef['DeviceIdentifier'] = entry.deviceId;
    }

    return clef;
  }

  String toNdjsonLine(LogEntry entry) => jsonEncode(toClef(entry));
}