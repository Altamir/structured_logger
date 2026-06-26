import 'package:flutter/material.dart';

import '../models/active_filter_chip_data.dart';
import '../theme/clef_design_system.dart';

export '../models/active_filter_chip_data.dart';

class ActiveFilterChips extends StatelessWidget {
  final List<ActiveFilterChipData> chips;

  const ActiveFilterChips({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: ClefDs.spaceMd),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips
            .map<Widget>(
              (chip) => Semantics(
                label: 'Remover filtro ${chip.label}',
                child: InputChip(
                  label: Text(chip.label),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: chip.onRemove,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}