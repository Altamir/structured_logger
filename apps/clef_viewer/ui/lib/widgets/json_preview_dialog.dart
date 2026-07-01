import 'package:flutter/material.dart';

import '../utils/clipboard_helper.dart';

Future<void> showJsonPreviewDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: SelectableText(
            content,
            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fechar'),
        ),
        FilledButton(
          onPressed: () async {
            final copied = await copyTextToClipboard(context, content);
            if (copied && dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
          },
          child: const Text('Copiar'),
        ),
      ],
    ),
  );
}