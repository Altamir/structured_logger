import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../models/log_filter.dart';
import '../services/device_suggestion_cache.dart';
import '../utils/active_filter_chip_factory.dart';
import 'active_filter_chips.dart';
import 'device_id_field.dart';

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
  static const levelOptions = [
    'debug',
    'information',
    'info',
    'warning',
    'error',
    'fatal',
  ];

  late final TextEditingController _deviceController;
  late final TextEditingController _propertyController;
  late final TextEditingController _searchController;
  DateTime? _from;
  DateTime? _to;
  final Set<String> _selectedLevels = {};
  String? _validationError;
  LogFilter _appliedFilter = const LogFilter();

  @override
  void initState() {
    super.initState();
    _appliedFilter = widget.initialFilter;
    _from = widget.initialFilter.from;
    _to = widget.initialFilter.to;
    _selectedLevels.addAll(widget.initialFilter.levels);
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
      levels: _selectedLevels.toList(),
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
      _selectedLevels
        ..clear()
        ..addAll(filter.levels);
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

  @override
  Widget build(BuildContext context) {
    final activeChips = ActiveFilterChipFactory.fromFilter(
      _appliedFilter,
      _onActiveChipRemove,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                child: Text(_from == null ? 'From' : 'From: ${_from!.toLocal()}'),
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
                child: Text(_to == null ? 'To' : 'To: ${_to!.toLocal()}'),
              ),
              PopupMenuButton<String>(
                child: Chip(
                  label: Text(
                    _selectedLevels.isEmpty
                        ? 'Levels'
                        : _selectedLevels.join(', '),
                  ),
                ),
                itemBuilder: (context) => levelOptions
                    .map(
                      (level) => CheckedPopupMenuItem<String>(
                        value: level,
                        checked: _selectedLevels.contains(level),
                        child: Text(level),
                      ),
                    )
                    .toList(),
                onSelected: (level) {
                  setState(() {
                    if (_selectedLevels.contains(level)) {
                      _selectedLevels.remove(level);
                    } else {
                      _selectedLevels.add(level);
                    }
                  });
                },
              ),
              if (widget.deviceCache != null)
                DeviceIdField(
                  controller: _deviceController,
                  cache: widget.deviceCache!,
                  onDeviceSelected: _onDeviceSelected,
                )
              else
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _deviceController,
                    decoration: const InputDecoration(
                      labelText: 'Device ID',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _propertyController,
                  decoration: const InputDecoration(
                    labelText: 'Property (k=v)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(onPressed: apply, child: const Text('Apply')),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _from = null;
                    _to = null;
                    _selectedLevels.clear();
                    _deviceController.clear();
                    _propertyController.clear();
                    _searchController.clear();
                    _validationError = null;
                    _appliedFilter = const LogFilter();
                  });
                  widget.onClear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          ActiveFilterChips(chips: activeChips),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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