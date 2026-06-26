/// Aggregation bucket for group-by queries.
class GroupResult {
  final String key;
  final int count;

  const GroupResult({required this.key, required this.count});

  Map<String, dynamic> toJson() => {'key': key, 'count': count};
}

/// Supported group-by dimensions.
enum GroupBy {
  level,
  time,
  deviceId,
  property,
}

extension GroupByParsing on GroupBy {
  static GroupBy? fromString(String value) {
    switch (value) {
      case 'level':
        return GroupBy.level;
      case 'time':
        return GroupBy.time;
      case 'device_id':
        return GroupBy.deviceId;
      case 'property':
        return GroupBy.property;
      default:
        return null;
    }
  }
}

/// Time bucket granularity for group-by time.
enum TimeBucket {
  minute,
  hour,
  day,
}

extension TimeBucketParsing on TimeBucket {
  static TimeBucket? fromString(String value) {
    switch (value) {
      case 'minute':
        return TimeBucket.minute;
      case 'hour':
        return TimeBucket.hour;
      case 'day':
        return TimeBucket.day;
      default:
        return null;
    }
  }

  String get sqlFormat {
    switch (this) {
      case TimeBucket.minute:
        return '%Y-%m-%dT%H:%M:00Z';
      case TimeBucket.hour:
        return '%Y-%m-%dT%H:00:00Z';
      case TimeBucket.day:
        return '%Y-%m-%dT00:00:00Z';
    }
  }
}
