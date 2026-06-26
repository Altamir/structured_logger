import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';

class GroupPanel extends StatefulWidget {
  final String groupBy;
  final String timeBucket;
  final String propertyName;
  final List<GroupResult> groups;
  final ValueChanged<String> groupByChanged;
  final ValueChanged<String> timeBucketChanged;
  final ValueChanged<String> propertyNameChanged;
  final void Function(String key) onGroupSelected;
  final VoidCallback onRefresh;

  const GroupPanel({
    super.key,
    required this.groupBy,
    required this.timeBucket,
    required this.propertyName,
    required this.groups,
    required this.groupByChanged,
    required this.timeBucketChanged,
    required this.propertyNameChanged,
    required this.onGroupSelected,
    required this.onRefresh,
  });

  static LogFilter applyGroupFilter(
    LogFilter current,
    String groupBy,
    String key, {
    String propertyName = 'Screen',
  }) {
    switch (groupBy) {
      case 'level':
        return current.copyWith(levels: [key]);
      case 'device_id':
        if (key == '(empty)') {
          return current.copyWith(deviceId: FilterConstants.emptySentinel);
        }
        return current.copyWith(deviceId: key);
      case 'property':
        if (key == '(empty)') {
          return current.copyWith(
            property: '$propertyName=${FilterConstants.emptySentinel}',
          );
        }
        return current.copyWith(property: '$propertyName=$key');
      case 'time':
        final from = DateTime.parse(key).toUtc();
        DateTime to;
        if (key.endsWith('T00:00:00Z')) {
          to = from.add(const Duration(days: 1)).subtract(
                const Duration(milliseconds: 1),
              );
        } else if (key.endsWith(':00:00Z')) {
          to = from.add(const Duration(hours: 1)).subtract(
                const Duration(milliseconds: 1),
              );
        } else {
          to = from.add(const Duration(minutes: 1)).subtract(
                const Duration(milliseconds: 1),
              );
        }
        return current.copyWith(from: from, to: to);
      default:
        return current;
    }
  }

  @override
  State<GroupPanel> createState() => _GroupPanelState();
}

class _GroupPanelState extends State<GroupPanel> {
  late final TextEditingController _propertyController;

  @override
  void initState() {
    super.initState();
    _propertyController = TextEditingController(text: widget.propertyName);
  }

  @override
  void didUpdateWidget(GroupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyName != widget.propertyName &&
        _propertyController.text != widget.propertyName) {
      _propertyController.text = widget.propertyName;
    }
  }

  @override
  void dispose() {
    _propertyController.dispose();
    super.dispose();
  }

  void _applyPropertyName() {
    widget.propertyNameChanged(_propertyController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Group by:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: widget.groupBy,
                items: const [
                  DropdownMenuItem(value: 'level', child: Text('level')),
                  DropdownMenuItem(value: 'time', child: Text('time')),
                  DropdownMenuItem(value: 'device_id', child: Text('device_id')),
                  DropdownMenuItem(value: 'property', child: Text('property')),
                ],
                onChanged: (v) {
                  if (v != null) widget.groupByChanged(v);
                },
              ),
              if (widget.groupBy == 'time') ...[
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: widget.timeBucket,
                  items: const [
                    DropdownMenuItem(value: 'minute', child: Text('minute')),
                    DropdownMenuItem(value: 'hour', child: Text('hour')),
                    DropdownMenuItem(value: 'day', child: Text('day')),
                  ],
                  onChanged: (v) {
                    if (v != null) widget.timeBucketChanged(v);
                  },
                ),
              ],
              if (widget.groupBy == 'property') ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _propertyController,
                    decoration: const InputDecoration(
                      labelText: 'Property',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyPropertyName(),
                  ),
                ),
                IconButton(
                  tooltip: 'Apply property',
                  onPressed: _applyPropertyName,
                  icon: const Icon(Icons.check),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.groups.isEmpty
              ? const Center(child: Text('No groups for current filters.'))
              : ListView.builder(
                  itemCount: widget.groups.length,
                  itemBuilder: (context, index) {
                    final group = widget.groups[index];
                    return ListTile(
                      title: Text(group.key),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${group.count}'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => widget.onGroupSelected(group.key),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}