import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/widgets/display_message_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders plain renderedMessage without highlight', (tester) async {
    const entry = LogEntry(
      timestamp: '2024-01-01T12:00:01.000Z',
      level: 'info',
      renderedMessage: 'Already rendered',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DisplayMessageText(entry: entry)),
      ),
    );

    expect(find.text('Already rendered'), findsOneWidget);
    expect(find.byType(DisplayMessageText), findsOneWidget);
  });

  testWidgets('renders substituted template with RichText', (tester) async {
    const entry = LogEntry(
      timestamp: '2024-01-01T12:00:01.000Z',
      level: 'info',
      messageTemplate: 'Hello {name}',
      properties: {'name': 'Alice'},
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DisplayMessageText(entry: entry)),
      ),
    );

    expect(find.textContaining('Hello'), findsOneWidget);
    expect(find.textContaining('Alice'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('renders missing placeholder widget span', (tester) async {
    const entry = LogEntry(
      timestamp: '2024-01-01T12:00:01.000Z',
      level: 'info',
      messageTemplate: 'Hello {name}',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DisplayMessageText(entry: entry)),
      ),
    );

    expect(find.text('{name}'), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });
}