import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            final messenger = ScaffoldMessenger.of(context);
            try {
              await Clipboard.setData(ClipboardData(text: content));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Copiado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Falha ao copiar')),
                );
              }
            }
          },
          child: const Text('Copiar'),
        ),
      ],
    ),
  );
}