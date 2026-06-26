import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/utils/log_copy_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogCopyFormatter', () {
    test('formats full entry', () {
      const entry = LogEntry(
        timestamp: '2024-01-01T12:00:01.000Z',
        level: 'info',
        messageTemplate: 'User {id} logged in',
        deviceId: 'my-app-dev',
        exception: 'stack trace',
        properties: {'id': 42, 'Screen': 'Home'},
      );

      final text = LogCopyFormatter.format(entry);

      expect(text, contains('2024-01-01T12:00:01.000Z [info] User 42 logged in'));
      expect(text, contains('device: my-app-dev'));
      expect(text, contains('exception:'));
      expect(text, contains('stack trace'));
      expect(text, contains('properties: {"id":42,"Screen":"Home"}'));
    });

    test('omits optional lines', () {
      const entry = LogEntry(
        timestamp: '2024-01-01T12:00:01.000Z',
        level: 'error',
        renderedMessage: 'Failed',
      );

      final text = LogCopyFormatter.format(entry);
      expect(text, '2024-01-01T12:00:01.000Z [error] Failed');
      expect(text, isNot(contains('device:')));
      expect(text, isNot(contains('properties:')));
    });
  });
}