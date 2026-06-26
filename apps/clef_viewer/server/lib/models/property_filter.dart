import 'filter_constants.dart';

/// A single property equality filter (key = value).
class PropertyFilter {
  final String key;
  final String value;

  const PropertyFilter({required this.key, required this.value});
}

/// Parses and serialises multi-property filter query values.
abstract final class PropertyFilterCodec {
  static const separator = ';';

  static List<PropertyFilter> parseParam(String? propertyParam) {
    if (propertyParam == null || propertyParam.isEmpty) return [];

    final filters = <PropertyFilter>[];
    for (final part in propertyParam.split(separator)) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      filters.add(
        PropertyFilter(
          key: trimmed.substring(0, eqIndex),
          value: trimmed.substring(eqIndex + 1),
        ),
      );
    }
    return filters;
  }

  static String encode(List<PropertyFilter> filters) {
    if (filters.isEmpty) return '';
    return filters.map((f) => '${f.key}=${f.value}').join(separator);
  }

  static void validateAll(List<PropertyFilter> filters) {
    for (final filter in filters) {
      PropertyKeyValidator.validate(filter.key);
    }
  }
}
