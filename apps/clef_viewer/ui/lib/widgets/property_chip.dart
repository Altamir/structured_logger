import 'package:flutter/material.dart';

import '../utils/property_filter_helper.dart';

class PropertyChip extends StatelessWidget {
  final String propertyKey;
  final dynamic value;
  final ValueChanged<String> onFilter;

  const PropertyChip({
    super.key,
    required this.propertyKey,
    required this.value,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final filterable = PropertyFilterHelper.isFilterable(value);
    final label = '$propertyKey: ${PropertyFilterHelper.displayValue(value)}';
    final tooltip = filterable
        ? 'Filtrar por $propertyKey'
        : 'Valor complexo — não filtrável';

    final chip = ActionChip(
      label: Text(label),
      onPressed: filterable
          ? () => onFilter(PropertyFilterHelper.toFilterParam(propertyKey, value))
          : null,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Tooltip(
      message: tooltip,
      child: filterable ? chip : Opacity(opacity: 0.6, child: chip),
    );
  }
}