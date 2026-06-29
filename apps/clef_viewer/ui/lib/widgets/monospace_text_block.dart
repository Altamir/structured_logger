import 'package:flutter/material.dart';

import '../theme/clef_design_system.dart';
import '../utils/json_display_helper.dart';
import 'json_preview_dialog.dart';

class MonospaceTextBlock extends StatelessWidget {
  final String content;
  final String? previewTitle;
  final Color? color;
  final bool truncate;

  const MonospaceTextBlock({
    super.key,
    required this.content,
    this.previewTitle,
    this.color,
    this.truncate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.onSurfaceVariant;
    final displayText = truncate && JsonDisplayHelper.exceedsPreviewLimit(content)
        ? JsonDisplayHelper.previewText(content)
        : content;
    final showViewAll = truncate &&
        JsonDisplayHelper.exceedsPreviewLimit(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
        if (showViewAll)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showJsonPreviewDialog(
                context,
                title: previewTitle ?? 'Conteúdo completo',
                content: content,
              ),
              child: const Text('Ver completo'),
            ),
          ),
      ],
    );
  }
}