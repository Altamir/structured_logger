import 'package:flutter/material.dart';

import '../models/level_options.dart';
import '../theme/clef_design_system.dart';

/// Toggle chips for log levels — all selected by default in the UI.
class LevelFilterField extends StatelessWidget {
  final Set<String> selectedLevels;
  final ValueChanged<Set<String>> onChanged;

  const LevelFilterField({
    super.key,
    required this.selectedLevels,
    required this.onChanged,
  });

  void _toggle(String level) {
    final next = Set<String>.from(selectedLevels);
    if (next.contains(level)) {
      if (next.length == 1) return;
      next.remove(level);
    } else {
      next.add(level);
    }
    onChanged(next);
  }

  void _selectAll() => onChanged(LevelOptions.all.toSet());

  String _shortLabel(String level) {
    switch (level) {
      case 'information':
        return 'info';
      case 'warning':
        return 'warn';
      default:
        return level.length > 5 ? level.substring(0, 5) : level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = LevelOptions.isAllSelected(selectedLevels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Levels',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (!allSelected) ...[
              const SizedBox(width: ClefDs.spaceSm),
              TextButton(
                onPressed: _selectAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Todos'),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClefDs.spaceXs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: LevelOptions.all.map((level) {
            final selected = selectedLevels.contains(level);
            final color = ClefDs.levelColor(level);

            return FilterChip(
              label: Text(_shortLabel(level)),
              selected: selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              selectedColor: color.withValues(alpha: 0.18),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : ClefDs.appleTextSecondary,
              ),
              side: BorderSide(
                color: selected
                    ? color.withValues(alpha: 0.5)
                    : ClefDs.appleSeparator.withValues(alpha: 0.5),
              ),
              onSelected: (_) => _toggle(level),
            );
          }).toList(),
        ),
      ],
    );
  }
}