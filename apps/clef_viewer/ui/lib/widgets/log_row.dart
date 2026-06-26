import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/log_entry.dart';
import '../utils/log_copy_formatter.dart';
import 'display_message_text.dart';
import 'level_badge.dart';
import 'property_chip.dart';

class LogRow extends StatefulWidget {
  final LogEntry entry;
  final ValueChanged<String>? onPropertyFilter;

  const LogRow({
    super.key,
    required this.entry,
    this.onPropertyFilter,
  });

  @override
  State<LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<LogRow> {
  bool _expanded = false;
  bool _hovering = false;

  Future<void> _copyLog() async {
    final text = LogCopyFormatter.format(widget.entry);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Copiado'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Falha ao copiar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.parse(widget.entry.timestamp).toLocal();
    final timeLabel =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
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
                      child: DisplayMessageText(
                        entry: widget.entry,
                        maxLines: _expanded ? null : 1,
                        overflow:
                            _expanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                    if (_hovering || _expanded)
                      Semantics(
                        label: 'Copiar log',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copiar log',
                          onPressed: _copyLog,
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
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.entry.properties.entries
                            .map(
                              (e) => PropertyChip(
                                propertyKey: e.key,
                                value: e.value,
                                onFilter: widget.onPropertyFilter ?? (_) {},
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}