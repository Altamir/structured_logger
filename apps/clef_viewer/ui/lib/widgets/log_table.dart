import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../theme/clef_design_system.dart';
import 'log_row.dart';

class LogTable extends StatelessWidget {
  final List<LogEntry> events;
  final int total;
  final ValueChanged<String>? onPropertyFilter;

  const LogTable({
    super.key,
    required this.events,
    required this.total,
    this.onPropertyFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        right: ClefDs.spaceMd,
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
              ClefDs.spaceLg,
              ClefDs.spaceMd,
              ClefDs.spaceLg,
              ClefDs.spaceSm,
            ),
            child: Row(
              children: [
                Text(
                  'Events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: ClefDs.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(ClefDs.radiusPill),
                  ),
                  child: Text(
                    '$total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'No events match the current filters.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: ClefDs.spaceXs),
                    itemCount: events.length,
                    itemBuilder: (context, index) => LogRow(
                      entry: events[index],
                      onPropertyFilter: onPropertyFilter,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}