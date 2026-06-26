import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../utils/message_template_renderer.dart';
import 'dashed_border.dart';

class DisplayMessageText extends StatelessWidget {
  final LogEntry entry;
  final int? maxLines;
  final TextOverflow? overflow;

  const DisplayMessageText({
    super.key,
    required this.entry,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.renderedMessage != null) {
      return Text(
        entry.renderedMessage!,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (entry.messageTemplate != null) {
      if (entry.messageTemplate!.isEmpty) {
        return Text(
          entry.exception ?? '(no message)',
          maxLines: maxLines,
          overflow: overflow,
        );
      }

      final segments = MessageTemplateRenderer.renderTemplate(
        entry.messageTemplate!,
        entry.properties,
      );
      if (segments != null) {
        return Text.rich(
          TextSpan(
            children: segments.map((s) => _spanForSegment(context, s)).toList(),
          ),
          maxLines: maxLines,
          overflow: overflow,
        );
      }
    }

    return Text(
      entry.exception ?? '(no message)',
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  InlineSpan _spanForSegment(BuildContext context, DisplayMessageSegment s) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;

    switch (s.kind) {
      case DisplaySegmentKind.plain:
        return TextSpan(text: s.text, style: baseStyle);
      case DisplaySegmentKind.substituted:
        return TextSpan(
          text: s.text,
          style: baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        );
      case DisplaySegmentKind.missing:
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: DashedBorder(
            color: theme.colorScheme.error,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                s.text,
                style: baseStyle?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ),
        );
    }
  }
}