import 'package:flutter/material.dart';

import '../models/log_filter.dart';

class FilterBar extends StatefulWidget {
  final LogFilter initialFilter;
  final ValueChanged<LogFilter> onApply;
  final VoidCallback onClear;

  const FilterBar({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onClear,
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
  late final TextEditingController _eventIdController;
  late final TextEditingController _propertyController;
  late final TextEditingController _searchController;
  DateTime? _from;
  DateTime? _to;
  final Set<String> _selectedLevels = {};
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFilter.from;
    _to = widget.initialFilter.to;
    _selectedLevels.addAll(widget.initialFilter.levels);
    _deviceController = TextEditingController(text: widget.initialFilter.deviceId);
    _eventIdController = TextEditingController(text: widget.initialFilter.eventId);
    _propertyController = TextEditingController(text: widget.initialFilter.property);
    _searchController = TextEditingController(text: widget.initialFilter.search);
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _eventIdController.dispose();
    _propertyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  LogFilter buildFilter() {
    return LogFilter(
      from: _from,
      to: _to,
      levels: _selectedLevels.toList(),
      deviceId: _emptyToNull(_deviceController.text),
      eventId: _emptyToNull(_eventIdController.text),
      property: _emptyToNull(_propertyController.text),
      search: _emptyToNull(_searchController.text),
    );
  }

  void apply() {
    final filter = buildFilter();
    final error = filter.validate();
    setState(() => _validationError = error);
    if (error == null) {
      widget.onApply(filter);
    }
  }

  String? get validationError => _validationError;

  @override
  Widget build(BuildContext context) {
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
                width: 140,
                child: TextField(
                  controller: _eventIdController,
                  decoration: const InputDecoration(
                    labelText: 'Event ID',
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
                    _eventIdController.clear();
                    _propertyController.clear();
                    _searchController.clear();
                    _validationError = null;
                  });
                  widget.onClear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
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