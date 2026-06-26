import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../models/level_options.dart';
import '../models/log_filter.dart';
import '../services/device_suggestion_cache.dart';
import '../theme/clef_design_system.dart';
import '../utils/active_filter_chip_factory.dart';
import 'active_filter_chips.dart';
import 'device_id_field.dart';
import 'level_filter_field.dart';

class FilterBar extends StatefulWidget {
  final LogFilter initialFilter;
  final ValueChanged<LogFilter> onApply;
  final VoidCallback onClear;
  final DeviceSuggestionCache? deviceCache;

  const FilterBar({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onClear,
    this.deviceCache,
  });

  @override
  State<FilterBar> createState() => FilterBarState();
}

class FilterBarState extends State<FilterBar> {
  late final TextEditingController _deviceController;
  late final TextEditingController _propertyController;
  late final TextEditingController _searchController;
  DateTime? _from;
  DateTime? _to;
  late Set<String> _selectedLevels;
  String? _validationError;
  LogFilter _appliedFilter = const LogFilter();

  @override
  void initState() {
    super.initState();
    _appliedFilter = widget.initialFilter;
    _from = widget.initialFilter.from;
    _to = widget.initialFilter.to;
    _selectedLevels = LevelOptions.uiSelectionFromFilter(widget.initialFilter.levels);
    _deviceController = TextEditingController(
      text: _deviceIdToDisplay(widget.initialFilter.deviceId),
    );
    _propertyController = TextEditingController(
      text: widget.initialFilter.property ?? '',
    );
    _searchController = TextEditingController(
      text: widget.initialFilter.search ?? '',
    );
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _propertyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  LogFilter buildFilter() {
    return LogFilter(
      from: _from,
      to: _to,
      levels: LevelOptions.filterFromUiSelection(_selectedLevels),
      deviceId: _deviceIdFromController(),
      property: _emptyToNull(_propertyController.text),
      search: _emptyToNull(_searchController.text),
    );
  }

  void apply() {
    final filter = buildFilter();
    final error = filter.validate();
    setState(() => _validationError = error);
    if (error == null) {
      _appliedFilter = filter;
      widget.onApply(filter);
    }
  }

  void applyPropertyFilter(String propertyParam) {
    _propertyController.text = propertyParam;
    apply();
  }

  /// Syncs controllers and active chips from an externally applied filter.
  /// Does not call [onApply] — caller already updated page state.
  void applyExternalFilter(LogFilter filter) {
    _syncControllersFromFilter(filter);
  }

  String? get validationError => _validationError;

  void _syncControllersFromFilter(LogFilter filter, {bool notify = true}) {
    void update() {
      _from = filter.from;
      _to = filter.to;
      _selectedLevels = LevelOptions.uiSelectionFromFilter(filter.levels);
      _deviceController.text = _deviceIdToDisplay(filter.deviceId);
      _propertyController.text = filter.property ?? '';
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

  void _resetToDefaults() {
    setState(() {
      _from = null;
      _to = null;
      _selectedLevels = LevelOptions.all.toSet();
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
      _onActiveChipRemove,
    );

    return Container(
      margin: const EdgeInsets.all(ClefDs.spaceMd),
      padding: const EdgeInsets.all(ClefDs.spaceLg),
      decoration: ClefDs.surfaceCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LevelFilterField(
            selectedLevels: _selectedLevels,
            onChanged: (levels) => setState(() => _selectedLevels = levels),
          ),
          const SizedBox(height: ClefDs.spaceMd),
          Wrap(
            spacing: ClefDs.spaceSm,
            runSpacing: ClefDs.spaceSm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: _from ?? DateTime.now(),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_from ?? DateTime.now()),
                  );
                  if (time == null) return;
                  setState(() {
                    _from = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                child: Text(_from == null ? 'From' : _formatDateTime(_from!)),
              ),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: _to ?? DateTime.now(),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_to ?? DateTime.now()),
                  );
                  if (time == null) return;
                  setState(() {
                    _to = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                child: Text(_to == null ? 'To' : _formatDateTime(_to!)),
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
                    label: 'Property (k=v)',
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
              FilledButton(onPressed: apply, child: const Text('Apply')),
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

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
}