import '../models/active_filter_chip_data.dart';
import '../models/filter_constants.dart';
import '../models/log_filter.dart';

class ActiveFilterChipFactory {
  static List<ActiveFilterChipData> fromFilter(
    LogFilter filter,
    void Function(LogFilter updated) onApply,
  ) {
    final chips = <ActiveFilterChipData>[];

    for (final level in filter.levels) {
      chips.add(
        ActiveFilterChipData(
          id: 'level:$level',
          label: 'level: $level',
          onRemove: () {
            final newLevels = List<String>.from(filter.levels)..remove(level);
            onApply(filter.copyWith(levels: newLevels));
          },
        ),
      );
    }

    if (filter.deviceId != null) {
      final display = filter.deviceId == FilterConstants.emptySentinel
          ? '(empty)'
          : filter.deviceId!;
      chips.add(
        ActiveFilterChipData(
          id: 'device:$display',
          label: 'device: $display',
          onRemove: () => onApply(filter.copyWith(deviceId: null)),
        ),
      );
    }

    if (filter.property != null && filter.property!.isNotEmpty) {
      chips.add(
        ActiveFilterChipData(
          id: 'property:${filter.property}',
          label: 'property: ${filter.property}',
          onRemove: () => onApply(filter.copyWith(property: null)),
        ),
      );
    }

    if (filter.search != null && filter.search!.isNotEmpty) {
      chips.add(
        ActiveFilterChipData(
          id: 'search:${filter.search}',
          label: 'search: ${filter.search}',
          onRemove: () => onApply(filter.copyWith(search: null)),
        ),
      );
    }

    return chips;
  }
}