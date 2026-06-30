import '../config/viewer_config.dart';
import 'log_filter.dart';

enum TimeWindowKind { liveNow, customRange }

/// How the viewer constrains event timestamps for queries and SSE.
class ViewerTimeWindow {
  final TimeWindowKind kind;
  final DateTime? customFrom;
  final DateTime? customTo;

  /// After the first successful load in [liveNow], use the steady window (3 min).
  final bool liveSteady;

  const ViewerTimeWindow({
    this.kind = TimeWindowKind.liveNow,
    this.customFrom,
    this.customTo,
    this.liveSteady = false,
  });

  ViewerTimeWindow copyWith({
    TimeWindowKind? kind,
    Object? customFrom = _unset,
    Object? customTo = _unset,
    bool? liveSteady,
  }) {
    return ViewerTimeWindow(
      kind: kind ?? this.kind,
      customFrom: identical(customFrom, _unset)
          ? this.customFrom
          : customFrom as DateTime?,
      customTo:
          identical(customTo, _unset) ? this.customTo : customTo as DateTime?,
      liveSteady: liveSteady ?? this.liveSteady,
    );
  }

  Duration liveDuration() {
    return liveSteady ? ViewerConfig.liveWindowSteady : ViewerConfig.liveWindowBoot;
  }

  /// Merges [base] with effective from/to for API queries and client-side match.
  LogFilter applyTo(LogFilter base, DateTime nowUtc) {
    switch (kind) {
      case TimeWindowKind.liveNow:
        final window = liveDuration();
        return base.copyWith(
          from: nowUtc.subtract(window),
          to: null,
        );
      case TimeWindowKind.customRange:
        return base.copyWith(from: customFrom, to: customTo);
    }
  }

  String? validate() {
    if (kind != TimeWindowKind.customRange) return null;
    if (customFrom != null &&
        customTo != null &&
        customFrom!.isAfter(customTo!)) {
      return 'From date must be before to date';
    }
    return null;
  }

  static const _unset = Object();
}