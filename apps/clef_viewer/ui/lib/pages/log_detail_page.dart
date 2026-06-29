import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/log_entry.dart';
import '../theme/clef_design_system.dart';
import '../utils/json_display_helper.dart';
import '../utils/log_copy_formatter.dart';
import '../utils/property_filter_helper.dart';
import '../widgets/display_message_text.dart';
import '../widgets/json_value_block.dart';
import '../widgets/level_badge.dart';
import '../widgets/monospace_text_block.dart';
import '../widgets/property_chip.dart';

class LogDetailPage extends StatelessWidget {
  final LogEntry entry;
  final ValueChanged<String>? onPropertyFilter;

  const LogDetailPage({
    super.key,
    required this.entry,
    this.onPropertyFilter,
  });

  Future<void> _copyLog(BuildContext context) async {
    final text = LogCopyFormatter.format(entry);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Copiado'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Falha ao copiar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ts = DateTime.parse(entry.timestamp).toLocal();
    final timestampLabel = ts.toIso8601String();

    final primitiveProperties = <MapEntry<String, dynamic>>[];
    final structuredProperties = <MapEntry<String, dynamic>>[];

    for (final property in entry.properties.entries) {
      if (JsonDisplayHelper.isStructuredJsonValue(property.value)) {
        structuredProperties.add(property);
      } else if (PropertyFilterHelper.isFilterable(property.value)) {
        primitiveProperties.add(property);
      } else {
        structuredProperties.add(property);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar log',
            onPressed: () => _copyLog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClefDs.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Metadados',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetadataRow(label: 'Timestamp', value: timestampLabel),
                  const SizedBox(height: ClefDs.spaceSm),
                  Row(
                    children: [
                      Text(
                        'Level',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: ClefDs.spaceSm),
                      LevelBadge(level: entry.level),
                    ],
                  ),
                  if (entry.deviceId != null && entry.deviceId!.isNotEmpty) ...[
                    const SizedBox(height: ClefDs.spaceSm),
                    _MetadataRow(label: 'Device', value: entry.deviceId!),
                  ],
                  if (entry.messageTemplate != null) ...[
                    const SizedBox(height: ClefDs.spaceSm),
                    _MetadataRow(
                      label: 'Message Template',
                      value: entry.messageTemplate!,
                    ),
                  ],
                  if (entry.renderedMessage != null) ...[
                    const SizedBox(height: ClefDs.spaceSm),
                    _MetadataRow(
                      label: 'Rendered Message',
                      value: entry.renderedMessage!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ClefDs.spaceLg),
            _Section(
              title: 'Display Message',
              child: DisplayMessageText(entry: entry),
            ),
            if (entry.exception != null) ...[
              const SizedBox(height: ClefDs.spaceLg),
              _Section(
                title: 'Exception',
                child: MonospaceTextBlock(
                  content: entry.exception!,
                  previewTitle: 'Exception',
                  color: theme.colorScheme.error,
                  truncate: false,
                ),
              ),
            ],
            if (primitiveProperties.isNotEmpty) ...[
              const SizedBox(height: ClefDs.spaceLg),
              _Section(
                title: 'Properties',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: primitiveProperties
                      .map(
                        (property) => PropertyChip(
                          propertyKey: property.key,
                          value: property.value,
                          onFilter: onPropertyFilter ?? (_) {},
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (structuredProperties.isNotEmpty) ...[
              const SizedBox(height: ClefDs.spaceLg),
              _Section(
                title: primitiveProperties.isEmpty ? 'Properties' : 'Structured Properties',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: structuredProperties
                      .map(
                        (property) => JsonValueBlock(
                          propertyKey: property.key,
                          value: property.value,
                          truncate: false,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ClefDs.spaceSm),
        child,
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: ClefDs.spaceXs),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}