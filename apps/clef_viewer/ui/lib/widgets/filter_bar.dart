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
  final String initialSearch;
  final ViewerTimeWindow timeWindow;
  final ValueChanged<ViewerTimeWindow> onTimeWindowChanged;
  final ValueChanged<LogFilter> onApply;
  final VoidCallback onClear;
  final DeviceSuggestionCache? deviceCache;

  const FilterBar({
    super.key,
    required this.initialFilter,
    this.initialSearch = '',
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
  static const _textDebounce = Duration(milliseconds: 400);

  late final TextEditingController _deviceController;
  late final TextEditingController _searchController;
  String? _validationError;
  LogFilter _appliedFilter = const LogFilter();
  bool _searchLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _appliedFilter = widget.initialFilter;
    _deviceController = TextEditingController(
      text: _deviceIdToDisplay(widget.initialFilter.deviceId),
    );
    _searchController = TextEditingController(
      text: widget.initialSearch.isNotEmpty
          ? widget.initialSearch
          : (widget.initialFilter.search ?? ''),
    );

    if (widget.deviceCache == null) {
      _deviceController.addListener(_scheduleDeviceDebounce);
    }
    _searchController.addListener(_scheduleSearchDebounce);
  }

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _appliedFilter = _appliedFilter.copyWith(
          levels: widget.initialFilter.levels,
          deviceId: widget.initialFilter.deviceId,
          properties: widget.initialFilter.properties,
        );
        if (_deviceIdToDisplay(widget.initialFilter.deviceId) !=
            _deviceController.text) {
          _deviceController.text =
              _deviceIdToDisplay(widget.initialFilter.deviceId);
        }
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
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSearchDebounce() {
    setState(() => _searchLoading = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_textDebounce, () {
      apply();
      if (mounted) setState(() => _searchLoading = false);
    });
  }

  void _scheduleDeviceDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_textDebounce, apply);
  }

  LogFilter buildFilter() {
    return LogFilter(
      levels: widget.initialFilter.levels,
      deviceId: _deviceIdFromController(),
      properties: _appliedFilter.properties,
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
      _appliedFilter.properties,
      propertyParam,
    );
    setState(() {
      _appliedFilter = _appliedFilter.copyWith(properties: merged);
    });
    apply();
  }

  /// Syncs controllers and active chips from an externally applied filter.
  void applyExternalFilter(
    LogFilter filter, {
    ViewerTimeWindow? timeWindow,
    bool preserveSearch = false,
    bool clearSearch = false,
  }) {
    _syncFromFilter(
      filter,
      timeWindow: timeWindow,
      preserveSearch: preserveSearch,
      clearSearch: clearSearch,
    );
  }

  String? get validationError => _validationError;

  void _syncFromFilter(
    LogFilter filter, {
    ViewerTimeWindow? timeWindow,
    bool preserveSearch = false,
    bool clearSearch = false,
  }) {
    void update() {
      _deviceController.text = _deviceIdToDisplay(filter.deviceId);
      if (clearSearch) {
        _searchController.clear();
      } else if (!preserveSearch) {
        _searchController.text = filter.search ?? '';
      }
      _validationError = null;
      _appliedFilter = filter.copyWith(search: null);
      _searchLoading = false;
    }

    setState(update);
    if (timeWindow != null) {
      widget.onTimeWindowChanged(timeWindow);
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
    final clearSearch =
        (updated.search == null || updated.search!.isEmpty) &&
            _searchController.text.isNotEmpty;
    _syncFromFilter(
      updated,
      preserveSearch: !clearSearch,
      clearSearch: clearSearch,
    );
    widget.onApply(updated.copyWith(search: _emptyToNull(_searchController.text)));
  }

  void _onTimeWindowChanged(ViewerTimeWindow window) {
    widget.onTimeWindowChanged(window);
    setState(() => _validationError = window.validate());
  }

  void _resetToDefaults() {
    setState(() {
      _deviceController.clear();
      _searchController.clear();
      _validationError = null;
      _appliedFilter = const LogFilter();
      _searchLoading = false;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final activeChips = ActiveFilterChipFactory.fromFilter(
      _appliedFilter.copyWith(search: _emptyToNull(_searchController.text)),
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
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: ClefDs.inputDecoration(
                    context: context,
                    label: 'Search',
                    hintText: 'Message, properties, device…',
                    suffixIcon: _searchLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
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