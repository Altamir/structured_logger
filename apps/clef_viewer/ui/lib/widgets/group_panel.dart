import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../theme/clef_design_system.dart';
import 'level_filter_field.dart';

class GroupPanel extends StatefulWidget {
  final Set<String> selectedLevels;
  final ValueChanged<Set<String>> onLevelsChanged;
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
    required this.selectedLevels,
    required this.onLevelsChanged,
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
            properties: ['$propertyName=${FilterConstants.emptySentinel}'],
          );
        }
        return current.copyWith(properties: ['$propertyName=$key']);
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
    return Container(
      margin: const EdgeInsets.only(
        left: ClefDs.spaceMd,
        top: ClefDs.spaceMd,
        bottom: ClefDs.spaceMd,
      ),
      decoration: ClefDs.surfaceCard(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClefDs.spaceMd,
              ClefDs.spaceMd,
              ClefDs.spaceMd,
              ClefDs.spaceSm,
            ),
            child: LevelFilterField(
              selectedLevels: widget.selectedLevels,
              onChanged: widget.onLevelsChanged,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClefDs.spaceMd,
              ClefDs.spaceMd,
              ClefDs.spaceSm,
              ClefDs.spaceSm,
            ),
            child: Row(
              children: [
                Text(
                  'Groups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Atualizar grupos',
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClefDs.spaceMd),
            child: Wrap(
              spacing: ClefDs.spaceSm,
              runSpacing: ClefDs.spaceSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LabeledDropdown(
                  label: 'Group by',
                  value: widget.groupBy,
                  items: const [
                    ('level', 'Level'),
                    ('time', 'Time'),
                    ('device_id', 'Device'),
                    ('property', 'Property'),
                  ],
                  onChanged: widget.groupByChanged,
                ),
                if (widget.groupBy == 'time')
                  _LabeledDropdown(
                    label: 'Bucket',
                    value: widget.timeBucket,
                    items: const [
                      ('minute', 'Minute'),
                      ('hour', 'Hour'),
                      ('day', 'Day'),
                    ],
                    onChanged: widget.timeBucketChanged,
                  ),
                if (widget.groupBy == 'property') ...[
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _propertyController,
                      decoration: ClefDs.inputDecoration(
                        context: context,
                        label: 'Group key',
                        hintText: 'e.g. Screen',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded, size: 18),
                          onPressed: _applyPropertyName,
                        ),
                      ),
                      onSubmitted: (_) => _applyPropertyName(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ClefDs.spaceSm),
          const Divider(height: 1),
          Expanded(
            child: widget.groups.isEmpty
                ? Center(
                    child: Text(
                      'No groups for current filters.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: ClefDs.spaceXs),
                    itemCount: widget.groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final group = widget.groups[index];
                      return _GroupListTile(
                        title: group.key,
                        count: group.count,
                        onTap: () => widget.onGroupSelected(group.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: Theme.of(context).textTheme.bodySmall,
          items: items
              .map(
                (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _GroupListTile extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;

  const _GroupListTile({
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClefDs.spaceMd,
            vertical: ClefDs.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ClefDs.radiusPill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}