import 'package:flutter/material.dart';

import '../models/active_filter_chip_data.dart';

export '../models/active_filter_chip_data.dart';

class ActiveFilterChips extends StatelessWidget {
  final List<ActiveFilterChipData> chips;

  const ActiveFilterChips({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips
            .map<Widget>(
              (chip) => Semantics(
                label: 'Remover filtro ${chip.label}',
                child: InputChip(
                  label: Text(chip.label),
                  onDeleted: chip.onRemove,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}