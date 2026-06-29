import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/pages/log_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entry = LogEntry(
    timestamp: '2024-01-01T12:00:01.000Z',
    level: 'error',
    messageTemplate: 'Failed {action}',
    renderedMessage: 'Failed checkout',
    exception: 'System.Exception: boom',
    deviceId: 'device-1',
    properties: {
      'action': 'checkout',
      'Payload': {'items': [1, 2]},
    },
  );

  testWidgets('shows structured log sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LogDetailPage(entry: entry),
      ),
    );

    expect(find.text('Log Event'), findsOneWidget);
    expect(find.text('Metadados'), findsOneWidget);
    expect(find.text('Display Message'), findsOneWidget);
    expect(find.text('Exception'), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Structured Properties'), findsOneWidget);
    expect(find.text('device-1'), findsOneWidget);
    expect(find.textContaining('"items"'), findsOneWidget);
  });

  testWidgets('copy action copies log content', (tester) async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add(call.arguments['text'] as String);
      }
      return null;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LogDetailPage(entry: entry),
      ),
    );

    await tester.tap(find.byTooltip('Copiar log'));
    await tester.pump();

    expect(copied, isNotEmpty);
    expect(copied.first, contains('Failed checkout'));
    expect(copied.first, contains('device-1'));
  });
}