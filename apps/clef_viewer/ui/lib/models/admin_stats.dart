class AdminStats {
  final int eventCount;
  final int dbSizeBytes;
  final double logsPerSecondLastMinute;
  final double logsPerSecondLastHour;
  final List<PeriodBucket> totalByPeriod;
  final List<PeriodBucket> ingestPeaks;

  const AdminStats({
    required this.eventCount,
    required this.dbSizeBytes,
    required this.logsPerSecondLastMinute,
    required this.logsPerSecondLastHour,
    required this.totalByPeriod,
    required this.ingestPeaks,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      eventCount: json['event_count'] as int,
      dbSizeBytes: json['db_size_bytes'] as int,
      logsPerSecondLastMinute:
          (json['logs_per_second_last_minute'] as num).toDouble(),
      logsPerSecondLastHour:
          (json['logs_per_second_last_hour'] as num).toDouble(),
      totalByPeriod: (json['total_by_period'] as List<dynamic>)
          .map((e) => PeriodBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
      ingestPeaks: (json['ingest_peaks'] as List<dynamic>)
          .map((e) => PeriodBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PeriodBucket {
  final String period;
  final int count;

  const PeriodBucket({required this.period, required this.count});

  factory PeriodBucket.fromJson(Map<String, dynamic> json) {
    return PeriodBucket(
      period: json['period'] as String,
      count: json['count'] as int,
    );
  }
}