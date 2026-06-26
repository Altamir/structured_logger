import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import 'level_badge.dart';

class LogRow extends StatefulWidget {
  final LogEntry entry;

  const LogRow({super.key, required this.entry});

  @override
  State<LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<LogRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.parse(widget.entry.timestamp).toLocal();
    final timeLabel =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(timeLabel, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  LevelBadge(level: widget.entry.level),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.entry.displayMessage,
                      maxLines: _expanded ? null : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (widget.entry.deviceId != null &&
                  widget.entry.deviceId!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'device: ${widget.entry.deviceId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (_expanded) ...[
                if (widget.entry.exception != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.entry.exception!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (widget.entry.properties.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      const JsonEncoder.withIndent('  ')
                          .convert(widget.entry.properties),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}