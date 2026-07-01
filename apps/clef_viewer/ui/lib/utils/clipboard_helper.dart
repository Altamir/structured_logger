import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> copyTextToClipboard(
  BuildContext context,
  String text, {
  String successMessage = 'Copiado',
  String failureMessage = 'Falha ao copiar',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
    return false;
  }
}