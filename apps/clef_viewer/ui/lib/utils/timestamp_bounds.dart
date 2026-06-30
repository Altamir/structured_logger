/// Formats timestamp filter bounds to match CLEF `@t` from Dart loggers (local wall clock).
class TimestampBounds {
  /// Same axis as [DateTime.now().toIso8601String()] — local, often without `Z`.
  static String toQueryParam(DateTime value) {
    return value.toLocal().toIso8601String();
  }

  static DateTime compareInstant(DateTime value) {
    return value.toLocal();
  }
}