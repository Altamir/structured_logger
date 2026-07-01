import '../models/log_entry.dart';
import 'json_display_helper.dart';
import 'message_template_renderer.dart';

class LogCopyFormatter {
  static String format(LogEntry entry) {
    final lines = <String>[];
    lines.add('${entry.timestamp} [${entry.level}] ${_displayMessagePlain(entry)}');

    if (entry.deviceId != null && entry.deviceId!.isNotEmpty) {
      lines.add('device: ${entry.deviceId}');
    }

    if (entry.exception != null) {
      lines.add('exception:');
      lines.add(entry.exception!);
    }

    if (entry.properties.isNotEmpty) {
      lines.add('properties:');
      lines.add(JsonDisplayHelper.toPrettyJson(entry.properties));
    }

    return lines.join('\n');
  }

  static String _displayMessagePlain(LogEntry entry) {
    if (entry.renderedMessage != null) return entry.renderedMessage!;
    if (entry.messageTemplate != null) {
      return MessageTemplateRenderer.renderPlain(
        entry.messageTemplate!,
        entry.properties,
      );
    }
    return entry.exception ?? '(no message)';
  }
}