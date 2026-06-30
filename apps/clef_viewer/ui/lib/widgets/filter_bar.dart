import 'dart:async';

import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../models/log_filter.dart';
import '../models/viewer_time_window.dart';
import '../services/device_suggestion_cache.dart';
import '../theme/clef_design_system.dart';
import '../utils/active_filter_chip_factory.dart';
import '../utils/property_filter_codec.dart';
import 'active_filter_chips.dart';
import 'device_id_field.dart';
import 'time_window_selector.dart';

class FilterBar extends StatefulWidget {
  final LogFilter initialFilter;
  final ViewerTimeWindow timeWindow;
  final ValueChanged<ViewerTimeWindow> onTimeWindowChanged;
  final ValueChanged<LogFilter> onApply;
  final VoidCallback onClear;
  final DeviceSuggestionCache? deviceCache;

  const FilterBar({
    super.key,
    required this.initialFilter,
    required this.timeWindow,
    required this.onTimeWindowChanged,
    required this.onApply,
    required this.onClear,
    this.deviceCache,
  });

  @override
  State<FilterBar> createState() => FilterBarState();
}

class FilterBarState extends State<FilterBar> {
  static const _textDebounce = Duration(milliseconds: 450);

  late final TextEditingController _deviceController;
  late final TextEditingController _propertyController;
  late final TextEditingController _searchController;
  String? _validationError;
  LogFilter _appliedFilter = const LogFilter();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _appliedFilter = widget.initialFilter;
    _deviceController = TextEditingController(
      text: _deviceIdToDisplay(widget.initialFilter.deviceId),
    );
    _propertyController = TextEditingController(
      text: PropertyFilterCodec.encodeField(widget.initialFilter.properties),
    );
    _searchController = TextEditingController(
      text: widget.initialFilter.search ?? '',
    );

    if (widget.deviceCache == null) {
      _deviceController.addListener(_scheduleDebouncedApply);
    }
    _propertyController.addListener(_scheduleDebouncedApply);
    _searchController.addListener(_scheduleDebouncedApply);
  }

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _appliedFilter = _appliedFilter.copyWith(
          levels: widget.initialFilter.levels,
        );
      });
    }
    if (oldWidget.timeWindow != widget.timeWindow) {
      setState(() => _validationError = widget.timeWindow.validate());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _deviceController.dispose();
    _propertyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleDebouncedApply() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_textDebounce, apply);
  }

  LogFilter buildFilter() {
    return LogFilter(
      levels: widget.initialFilter.levels,
      deviceId: _deviceIdFromController(),
      properties: PropertyFilterCodec.parseField(_propertyController.text),
      search: _emptyToNull(_searchController.text),
    );
  }

  void apply() {
    final filter = buildFilter();
    final timeError = widget.timeWindow.validate();
    final filterError = filter.validate();
    final error = timeError ?? filterError;
    setState(() => _validationError = error);
    if (error == null) {
      _appliedFilter = filter;
      widget.onApply(filter);
    }
  }

  void applyPropertyFilter(String propertyParam) {
    final merged = PropertyFilterCodec.upsert(
      PropertyFilterCodec.parseField(_propertyController.text),
      propertyParam,
    );
    _propertyController.text = PropertyFilterCodec.encodeField(merged);
    apply();
  }

  /// Syncs controllers and active chips from an externally applied filter.
  void applyExternalFilter(LogFilter filter, {ViewerTimeWindow? timeWindow}) {
    _syncControllersFromFilter(filter);
    if (timeWindow != null) {
      widget.onTimeWindowChanged(timeWindow);
    }
  }

  String? get validationError => _validationError;

  void _syncControllersFromFilter(LogFilter filter, {bool notify = true}) {
    void update() {
      _deviceController.text = _deviceIdToDisplay(filter.deviceId);
      _propertyController.text = PropertyFilterCodec.encodeField(filter.properties);
      _searchController.text = filter.search ?? '';
      _validationError = null;
      _appliedFilter = filter;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  String _deviceIdToDisplay(String? deviceId) {
    if (deviceId == null) return '';
    if (deviceId == FilterConstants.emptySentinel) return '(empty)';
    return deviceId;
  }

  String? _deviceIdFromController() {
    final text = _deviceController.text.trim();
    if (text.isEmpty) return null;
    if (text == '(empty)') return FilterConstants.emptySentinel;
    return text;
  }

  void _onDeviceSelected(String? deviceId) {
    if (deviceId == FilterConstants.emptySentinel) {
      _deviceController.text = '(empty)';
    } else if (deviceId != null) {
      _deviceController.text = deviceId;
    }
    apply();
  }

  void _onActiveChipRemove(LogFilter updated) {
    _syncControllersFromFilter(updated);
    widget.onApply(updated);
  }

  void _onTimeWindowChanged(ViewerTimeWindow window) {
    widget.onTimeWindowChanged(window);
    setState(() => _validationError = window.validate());
  }

  void _resetToDefaults() {
    setState(() {
      _deviceController.clear();
      _propertyController.clear();
      _searchController.clear();
      _validationError = null;
      _appliedFilter = const LogFilter();
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final activeChips = ActiveFilterChipFactory.fromFilter(
      _appliedFilter,
      widget.timeWindow,
      _onActiveChipRemove,
      onClearTimeWindow: () {
        widget.onTimeWindowChanged(
          ViewerTimeWindow(liveSteady: widget.timeWindow.liveSteady),
        );
        apply();
      },
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        ClefDs.spaceMd,
        ClefDs.spaceSm,
        ClefDs.spaceMd,
        ClefDs.spaceSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClefDs.spaceMd,
        vertical: ClefDs.spaceSm,
      ),
      decoration: ClefDs.surfaceCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: ClefDs.spaceSm,
            runSpacing: ClefDs.spaceSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TimeWindowSelector(
                window: widget.timeWindow,
                onChanged: _onTimeWindowChanged,
              ),
              if (widget.deviceCache != null)
                DeviceIdField(
                  controller: _deviceController,
                  cache: widget.deviceCache!,
                  onDeviceSelected: _onDeviceSelected,
                )
              else
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _deviceController,
                    decoration: ClefDs.inputDecoration(
                      context: context,
                      label: 'Device ID',
                    ),
                  ),
                ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _propertyController,
                  decoration: ClefDs.inputDecoration(
                    context: context,
                    label: 'Property (k=v; k2=v2)',
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchController,
                  decoration: ClefDs.inputDecoration(
                    context: context,
                    label: 'Search',
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _resetToDefaults,
                child: const Text('Clear'),
              ),
            ],
          ),
          ActiveFilterChips(chips: activeChips),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: ClefDs.spaceSm),
              child: Text(
                _validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}