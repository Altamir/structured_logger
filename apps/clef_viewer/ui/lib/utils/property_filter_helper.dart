import 'dart:convert';

import '../models/filter_constants.dart';

class PropertyFilterHelper {
  static bool isFilterable(dynamic value) {
    if (value == null) return true;
    return value is String || value is num || value is bool;
  }

  /// Returns "Key=value" or "Key=__empty__" for null.
  static String toFilterParam(String key, dynamic value) {
    if (value == null) {
      return '$key=${FilterConstants.emptySentinel}';
    }
    return '$key=$value';
  }

  static String displayValue(dynamic value) {
    if (value == null) return '(empty)';
    if (value is String || value is num || value is bool) {
      return value.toString();
    }
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }
}