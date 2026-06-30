import 'package:flutter/material.dart';

import '../models/viewer_time_window.dart';
import '../theme/clef_design_system.dart';

typedef TimeWindowChanged = void Function(ViewerTimeWindow window);

/// Single control for live "Now" vs historical range presets / custom interval.
class TimeWindowSelector extends StatelessWidget {
  final ViewerTimeWindow window;
  final TimeWindowChanged onChanged;

  const TimeWindowSelector({
    super.key,
    required this.window,
    required this.onChanged,
  });

  static const _presets = <(String, Duration)>[
    ('Últimos 5 min', Duration(minutes: 5)),
    ('Últimos 15 min', Duration(minutes: 15)),
    ('Última 1 h', Duration(hours: 1)),
    ('Últimas 24 h', Duration(hours: 24)),
  ];

  String _buttonLabel() {
    if (window.kind == TimeWindowKind.liveNow) return 'Now';
    final from = window.customFrom;
    final to = window.customTo;
    if (from == null && to == null) return 'Range';
    if (from != null && to != null) {
      return '${_formatShort(from)} – ${_formatShort(to)}';
    }
    if (from != null) return 'Desde ${_formatShort(from)}';
    if (to != null) return 'Até ${_formatShort(to)}';
    return 'Range';
  }

  String _formatShort(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  void _selectLiveNow() {
    onChanged(
      ViewerTimeWindow(
        kind: TimeWindowKind.liveNow,
        liveSteady: window.liveSteady,
      ),
    );
  }

  void _selectPreset(Duration span) {
    final now = DateTime.now().toUtc();
    onChanged(
      ViewerTimeWindow(
        kind: TimeWindowKind.customRange,
        customFrom: now.subtract(span),
        customTo: now,
        liveSteady: window.liveSteady,
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final from = await _pickDateTime(
      context,
      title: 'From',
      initial: window.customFrom ?? DateTime.now(),
    );
    if (from == null || !context.mounted) return;

    final to = await _pickDateTime(
      context,
      title: 'To',
      initial: window.customTo ?? DateTime.now(),
    );
    if (to == null || !context.mounted) return;

    onChanged(
      ViewerTimeWindow(
        kind: TimeWindowKind.customRange,
        customFrom: from.toUtc(),
        customTo: to.toUtc(),
        liveSteady: window.liveSteady,
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required String title,
    required DateTime initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      helpText: title,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initial,
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      helpText: title,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLive = window.kind == TimeWindowKind.liveNow;

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: _selectLiveNow,
          child: Row(
            children: [
              if (isLive) const Icon(Icons.check, size: 18),
              if (isLive) const SizedBox(width: ClefDs.spaceSm),
              const Text('Now (ao vivo)'),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final (label, span) in _presets)
          MenuItemButton(
            onPressed: () => _selectPreset(span),
            child: Text(label),
          ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: () => _pickCustom(context),
          child: const Text('Intervalo personalizado…'),
        ),
      ],
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(
            isLive ? Icons.sensors : Icons.date_range,
            size: 18,
          ),
          label: Text(_buttonLabel()),
        );
      },
    );
  }
}