import 'package:flutter/material.dart';

Future<bool?> showConfirmDeleteDialog(
  BuildContext context, {
  required bool filtered,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(filtered ? 'Clear Filtered Logs' : 'Clear All Logs'),
      content: Text(
        filtered
            ? 'This will permanently delete logs matching the active filters. Continue?'
            : 'This will permanently delete all logs. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}