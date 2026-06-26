import 'filter_constants.dart';
import 'log_entry.dart';

class LogFilter {
  final DateTime? from;
  final DateTime? to;
  final List<String> levels;
  final String? deviceId;
  final String? eventId;
  final String? property;
  final String? search;

  const LogFilter({
    this.from,
    this.to,
    this.levels = const [],
    this.deviceId,
    this.eventId,
    this.property,
    this.search,
  });

  bool get hasActiveFilters =>
      from != null ||
      to != null ||
      levels.isNotEmpty ||
      deviceId != null ||
      (eventId != null && eventId!.isNotEmpty) ||
      (property != null && property!.isNotEmpty) ||
      (search != null && search!.isNotEmpty);

  String? validate() {
    if (from != null && to != null && from!.isAfter(to!)) {
      return 'From date must be before to date';
    }
    return null;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (from != null) params['from'] = from!.toUtc().toIso8601String();
    if (to != null) params['to'] = to!.toUtc().toIso8601String();
    if (levels.isNotEmpty) params['levels'] = levels.join(',');
    if (deviceId != null) {
      params['device_id'] = deviceId!;
    }
    if (eventId != null && eventId!.isNotEmpty) {
      params['event_id'] = eventId!;
    }
    if (property != null && property!.isNotEmpty) {
      params['property'] = property!;
    }
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    return params;
  }

  bool matches(LogEntry entry) {
    if (from != null) {
      final ts = DateTime.parse(entry.timestamp).toUtc();
      if (ts.isBefore(from!)) return false;
    }
    if (to != null) {
      final ts = DateTime.parse(entry.timestamp).toUtc();
      if (ts.isAfter(to!)) return false;
    }
    if (levels.isNotEmpty && !levels.contains(entry.level)) return false;
    if (deviceId != null) {
      if (deviceId == FilterConstants.emptySentinel) {
        if (entry.deviceId != null && entry.deviceId!.isNotEmpty) {
          return false;
        }
      } else if (entry.deviceId != deviceId) {
        return false;
      }
    }
    if (eventId != null && eventId!.isNotEmpty && entry.eventId != eventId) {
      return false;
    }
    if (property != null && property!.isNotEmpty) {
      final eq = property!.indexOf('=');
      if (eq > 0) {
        final key = property!.substring(0, eq);
        final value = property!.substring(eq + 1);
        if (value == FilterConstants.emptySentinel) {
          if (entry.properties[key] != null) return false;
        } else if (entry.properties[key]?.toString() != value) {
          return false;
        }
      }
    }
    if (search != null && search!.isNotEmpty) {
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

  LogFilter copyWith({
    DateTime? from,
    DateTime? to,
    List<String>? levels,
    String? deviceId,
    String? eventId,
    String? property,
    String? search,
  }) {
    return LogFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      levels: levels ?? this.levels,
      deviceId: deviceId ?? this.deviceId,
      eventId: eventId ?? this.eventId,
      property: property ?? this.property,
      search: search ?? this.search,
    );
  }
}