import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import 'log_row.dart';

class LogTable extends StatelessWidget {
  final List<LogEntry> events;
  final int total;

  const LogTable({
    super.key,
    required this.events,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Events ($total total)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('No events match the current filters.'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) => LogRow(entry: events[index]),
                ),
        ),
      ],
    );
  }
}