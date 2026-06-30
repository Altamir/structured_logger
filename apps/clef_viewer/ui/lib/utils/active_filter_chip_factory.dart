import '../models/active_filter_chip_data.dart';
import '../models/filter_constants.dart';
import '../models/log_filter.dart';
import '../models/viewer_time_window.dart';
import 'property_filter_codec.dart';

class ActiveFilterChipFactory {
  static List<ActiveFilterChipData> fromFilter(
    LogFilter filter,
    ViewerTimeWindow timeWindow,
    void Function(LogFilter updated) onApply, {
    void Function()? onClearTimeWindow,
  }) {
    final chips = <ActiveFilterChipData>[];

    if (timeWindow.kind == TimeWindowKind.customRange) {
      chips.add(
        ActiveFilterChipData(
          id: 'time:range',
          label: 'time: range',
          onRemove: onClearTimeWindow ?? () {},
        ),
      );
    }

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

    for (final property in filter.properties) {
      chips.add(
        ActiveFilterChipData(
          id: 'property:$property',
          label: 'property: $property',
          onRemove: () {
            final key = PropertyFilterCodec.keyOf(property);
            if (key == null) return;
            onApply(
              filter.copyWith(
                properties: PropertyFilterCodec.removeKey(filter.properties, key),
              ),
            );
          },
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