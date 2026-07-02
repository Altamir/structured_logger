import 'package:flutter/material.dart';

import '../theme/clef_design_system.dart';
import '../utils/clipboard_helper.dart';
import '../utils/json_display_helper.dart';
import 'json_preview_dialog.dart';

class JsonValueBlock extends StatelessWidget {
  final String propertyKey;
  final dynamic value;
  final bool truncate;

  const JsonValueBlock({
    super.key,
    required this.propertyKey,
    required this.value,
    this.truncate = true,
  });

  Future<void> _copyJson(BuildContext context, String prettyJson) {
    return copyTextToClipboard(context, prettyJson);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prettyJson = JsonDisplayHelper.toPrettyJson(value);
    final displayText = truncate && JsonDisplayHelper.exceedsPreviewLimit(prettyJson)
        ? JsonDisplayHelper.previewText(prettyJson)
        : prettyJson;
    final showViewAll = truncate &&
        JsonDisplayHelper.exceedsPreviewLimit(prettyJson);

    return Padding(
      padding: const EdgeInsets.only(bottom: ClefDs.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(propertyKey, style: theme.textTheme.bodySmall),
              ),
              Semantics(
                label: 'Copiar JSON de $propertyKey',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copiar JSON',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _copyJson(context, prettyJson),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClefDs.spaceXs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClefDs.spaceSm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ClefDs.radiusMd),
            ),
            child: SelectableText(
              displayText,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          if (showViewAll)
            TextButton(
              onPressed: () => showJsonPreviewDialog(
                context,
                title: propertyKey,
                content: prettyJson,
              ),
              child: const Text('Ver completo'),
            ),
        ],
      ),
    );
  }
}