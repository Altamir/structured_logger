/// Filter bounds for TEXT `timestamp` column (legacy local ISO without `Z`).
class TimestampBounds {
  static DateTime? parseQueryParam(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.parse(value);
  }
}