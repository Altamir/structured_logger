import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/log_entry.dart';
import '../pages/log_detail_page.dart';
import '../theme/clef_design_system.dart';
import '../utils/json_display_helper.dart';
import '../utils/log_copy_formatter.dart';
import '../utils/property_filter_helper.dart';
import 'display_message_text.dart';
import 'json_value_block.dart';
import 'level_badge.dart';
import 'monospace_text_block.dart';
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

  void _openLogDetail() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LogDetailPage(
          entry: widget.entry,
          onPropertyFilter: widget.onPropertyFilter,
        ),
      ),
    );
  }

  Iterable<MapEntry<String, dynamic>> get _primitiveProperties sync* {
    for (final property in widget.entry.properties.entries) {
      if (JsonDisplayHelper.isStructuredJsonValue(property.value)) continue;
      if (PropertyFilterHelper.isFilterable(property.value)) {
        yield property;
      }
    }
  }

  Iterable<MapEntry<String, dynamic>> get _structuredProperties sync* {
    for (final property in widget.entry.properties.entries) {
      if (JsonDisplayHelper.isStructuredJsonValue(property.value)) {
        yield property;
        continue;
      }
      if (!PropertyFilterHelper.isFilterable(property.value)) {
        yield property;
      }
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
                      padding: const EdgeInsets.only(top: ClefDs.spaceSm),
                      child: MonospaceTextBlock(
                        content: widget.entry.exception!,
                        previewTitle: 'Exception',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_primitiveProperties.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: ClefDs.spaceSm),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _primitiveProperties
                            .map(
                              (property) => PropertyChip(
                                propertyKey: property.key,
                                value: property.value,
                                onFilter: widget.onPropertyFilter ?? (_) {},
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (_structuredProperties.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: ClefDs.spaceSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _structuredProperties
                            .map(
                              (property) => JsonValueBlock(
                                propertyKey: property.key,
                                value: property.value,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: ClefDs.spaceXs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _openLogDetail,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Ver log completo'),
                      ),
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