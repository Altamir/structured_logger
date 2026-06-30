import 'filter_constants.dart';
import 'log_entry.dart';
import '../utils/property_filter_codec.dart';
import '../utils/timestamp_bounds.dart';

class LogFilter {
  final DateTime? from;
  final DateTime? to;
  final List<String> levels;
  final String? deviceId;
  final String? eventId;
  final List<String> properties;
  final String? search;

  const LogFilter({
    this.from,
    this.to,
    this.levels = const [],
    this.deviceId,
    this.eventId,
    this.properties = const [],
    this.search,
  });

  bool get hasActiveFilters =>
      from != null ||
      to != null ||
      levels.isNotEmpty ||
      deviceId != null ||
      (eventId != null && eventId!.isNotEmpty) ||
      properties.isNotEmpty ||
      (search != null && search!.isNotEmpty);

  String? validate() {
    if (from != null && to != null && from!.isAfter(to!)) {
      return 'From date must be before to date';
    }
    return null;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (from != null) params['from'] = TimestampBounds.toQueryParam(from!);
    if (to != null) params['to'] = TimestampBounds.toQueryParam(to!);
    if (levels.isNotEmpty) params['levels'] = levels.join(',');
    if (deviceId != null) {
      params['device_id'] = deviceId!;
    }
    if (eventId != null && eventId!.isNotEmpty) {
      params['event_id'] = eventId!;
    }
    if (properties.isNotEmpty) {
      params['property'] = PropertyFilterCodec.encodeField(properties);
    }
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    return params;
  }

  bool matches(LogEntry entry) {
    if (from != null) {
      final ts = TimestampBounds.compareInstant(DateTime.parse(entry.timestamp));
      if (ts.isBefore(TimestampBounds.compareInstant(from!))) return false;
    }
    if (to != null) {
      final ts = TimestampBounds.compareInstant(DateTime.parse(entry.timestamp));
      if (ts.isAfter(TimestampBounds.compareInstant(to!))) return false;
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
    for (final property in properties) {
      final eq = property.indexOf('=');
      if (eq <= 0) continue;
      final key = property.substring(0, eq);
      final value = property.substring(eq + 1);
      if (value == FilterConstants.emptySentinel) {
        if (entry.properties[key] != null) return false;
      } else if (entry.properties[key]?.toString() != value) {
        return false;
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

  static const _unset = Object();

  LogFilter copyWith({
    Object? from = _unset,
    Object? to = _unset,
    List<String>? levels,
    Object? deviceId = _unset,
    Object? eventId = _unset,
    List<String>? properties,
    Object? search = _unset,
  }) {
    return LogFilter(
      from: identical(from, _unset) ? this.from : from as DateTime?,
      to: identical(to, _unset) ? this.to : to as DateTime?,
      levels: levels ?? this.levels,
      deviceId: identical(deviceId, _unset) ? this.deviceId : deviceId as String?,
      eventId: identical(eventId, _unset) ? this.eventId : eventId as String?,
      properties: properties ?? this.properties,
      search: identical(search, _unset) ? this.search : search as String?,
    );
  }
}