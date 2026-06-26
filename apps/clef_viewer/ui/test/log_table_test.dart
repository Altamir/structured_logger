import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/widgets/log_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LogTable renders events', (tester) async {
    const events = [
      LogEntry(
        timestamp: '2024-01-01T12:00:01.000Z',
        level: 'info',
        messageTemplate: 'Hello {name}',
        deviceId: 'my-device',
      ),
      LogEntry(
        timestamp: '2024-01-01T12:00:02.000Z',
        level: 'error',
        messageTemplate: 'Request failed',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogTable(events: events, total: 2),
        ),
      ),
    );

    expect(find.text('Events (2 total)'), findsOneWidget);
    expect(find.text('Hello {name}'), findsOneWidget);
    expect(find.text('Request failed'), findsOneWidget);
    expect(find.text('device: my-device'), findsOneWidget);
  });

  testWidgets('LogTable shows empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LogTable(events: [], total: 0),
        ),
      ),
    );

    expect(find.text('No events match the current filters.'), findsOneWidget);
  });
}