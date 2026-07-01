import 'dart:convert';

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
      expect(text, contains('properties:'));
      expect(text, contains('\n  "id": 42'));
      expect(text, contains('"Screen": "Home"'));

      final jsonStart = text.indexOf('{\n');
      final decoded = jsonDecode(text.substring(jsonStart)) as Map<String, dynamic>;
      expect(decoded['id'], 42);
      expect(decoded['Screen'], 'Home');
    });

    test('formats dart repr in properties as valid json', () {
      const address =
          'CustomerAddress({id: 1, principal: true, street: Main St, number: 10})';
      final entry = LogEntry(
        timestamp: '2024-01-01T12:00:01.000Z',
        level: 'info',
        renderedMessage: 'REQUEST',
        properties: {
          'data': {
            'addresses': [address],
          },
        },
      );

      final text = LogCopyFormatter.format(entry);
      final jsonStart = text.indexOf('{\n');
      final decoded = jsonDecode(text.substring(jsonStart)) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final addresses = data['addresses'] as List<dynamic>;

      expect(addresses.first, isA<Map<String, dynamic>>());
      expect(addresses.first['street'], 'Main St');
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