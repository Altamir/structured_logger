import 'filter_constants.dart';
import 'log_entry.dart';
import 'property_filter.dart';
import 'validation_exception.dart';

export 'validation_exception.dart';

/// Shared filter object for query, group, delete, and export.
class LogFilter {
  final DateTime? from;
  final DateTime? to;
  final List<String>? levels;
  final String? deviceId;
  final String? eventId;
  final List<PropertyFilter> properties;
  final String? search;

  const LogFilter({
    this.from,
    this.to,
    this.levels,
    this.deviceId,
    this.eventId,
    this.properties = const [],
    this.search,
  });

  factory LogFilter.fromQueryParams(Map<String, String> params) {
    List<String>? levels;
    final levelsParam = params['levels'];
    if (levelsParam != null && levelsParam.isNotEmpty) {
      levels = levelsParam
          .split(',')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }

    final propertyFilters =
        PropertyFilterCodec.parseParam(params['property']);

    return LogFilter(
      from: _parseDate(params['from']),
      to: _parseDate(params['to']),
      levels: levels,
      deviceId: _parseDeviceId(params['device_id']),
      eventId: _emptyToNull(params['event_id']),
      properties: propertyFilters,
      search: _emptyToNull(params['search']),
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.parse(value).toUtc();
  }

  static String? _parseDeviceId(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value == FilterConstants.emptySentinel) {
      return FilterConstants.emptySentinel;
    }
    return value;
  }

  static String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  void validate() {
    if (from != null && to != null && from!.isAfter(to!)) {
      throw ValidationException('From date must be before to date');
    }
    PropertyFilterCodec.validateAll(properties);
  }

  bool get isEmpty =>
      from == null &&
      to == null &&
      (levels == null || levels!.isEmpty) &&
      deviceId == null &&
      eventId == null &&
      properties.isEmpty &&
      search == null;

  /// Returns SQL WHERE clause (without "WHERE") and bound parameters.
  (String where, List<Object?> params) toSql() {
    final clauses = <String>[];
    final parameters = <Object?>[];

    if (from != null) {
      clauses.add('timestamp >= ?');
      parameters.add(from!.toIso8601String());
    }
    if (to != null) {
      clauses.add('timestamp <= ?');
      parameters.add(to!.toIso8601String());
    }
    if (levels != null && levels!.isNotEmpty) {
      final placeholders = List.filled(levels!.length, '?').join(', ');
      clauses.add('level IN ($placeholders)');
      parameters.addAll(levels!);
    }
    if (deviceId != null) {
      if (deviceId == FilterConstants.emptySentinel) {
        clauses.add("(device_id IS NULL OR device_id = '')");
      } else {
        clauses.add('device_id = ?');
        parameters.add(deviceId);
      }
    }
    if (eventId != null) {
      clauses.add('event_id = ?');
      parameters.add(eventId);
    }
    for (final property in properties) {
      final path = PropertyKeyValidator.jsonExtractPath(property.key);
      if (property.value == FilterConstants.emptySentinel) {
        clauses.add("json_extract(properties, '$path') IS NULL");
      } else {
        clauses.add(
          "CAST(json_extract(properties, '$path') AS TEXT) = ?",
        );
        parameters.add(property.value);
      }
    }
    if (search != null) {
      clauses.add(
        '(LOWER(message_template) LIKE ? OR LOWER(rendered_message) LIKE ? OR LOWER(exception) LIKE ?)',
      );
      final pattern = '%${search!.toLowerCase()}%';
      parameters.addAll([pattern, pattern, pattern]);
    }

    final where = clauses.isEmpty ? '1=1' : clauses.join(' AND ');
    return (where, parameters);
  }

  /// Client-side match for SSE events (mirrors server filter logic).
  bool matches(LogEntry entry) {
    if (from != null) {
      final ts = DateTime.parse(entry.timestamp).toUtc();
      if (ts.isBefore(from!)) return false;
    }
    if (to != null) {
      final ts = DateTime.parse(entry.timestamp).toUtc();
      if (ts.isAfter(to!)) return false;
    }
    if (levels != null && levels!.isNotEmpty) {
      if (!levels!.contains(entry.level)) return false;
    }
    if (deviceId != null) {
      if (deviceId == FilterConstants.emptySentinel) {
        if (entry.deviceId != null && entry.deviceId!.isNotEmpty) {
          return false;
        }
      } else if (entry.deviceId != deviceId) {
        return false;
      }
    }
    if (eventId != null && entry.eventId != eventId) return false;
    for (final property in properties) {
      final value = entry.properties[property.key];
      if (property.value == FilterConstants.emptySentinel) {
        if (value != null) return false;
      } else if (value?.toString() != property.value) {
        return false;
      }
    }
    if (search != null) {
      final q = search!.toLowerCase();
      final haystacks = [
        entry.messageTemplate,
        entry.renderedMessage,
        entry.exception,
      ];
      if (!haystacks.any((h) => h != null && h.toLowerCase().contains(q))) {
        return false;
      }
    }
    return true;
  }
}