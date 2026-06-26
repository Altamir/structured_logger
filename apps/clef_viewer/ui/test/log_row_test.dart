import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/widgets/log_row.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const entry = LogEntry(
    timestamp: '2024-01-01T12:00:01.000Z',
    level: 'info',
    messageTemplate: 'Hello {name}',
    properties: {'name': 'Alice', 'UserId': 42},
  );

  testWidgets('copy button visible on hover when collapsed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LogRow(entry: entry)),
      ),
    );

    expect(find.byIcon(Icons.copy), findsNothing);

    final center = tester.getCenter(find.byType(Card));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    await gesture.moveTo(center);
    await tester.pump();

    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('copy tap does not expand collapsed card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LogRow(entry: entry)),
      ),
    );

    final center = tester.getCenter(find.byType(Card));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    await gesture.moveTo(center);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('copy button visible when expanded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LogRow(entry: entry)),
      ),
    );

    expect(find.byIcon(Icons.copy), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('copy tap does not collapse expanded card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LogRow(entry: entry)),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });

  testWidgets('property chip visible when expanded', (tester) async {
    String? filtered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogRow(
            entry: entry,
            onPropertyFilter: (param) => filtered = param,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('UserId: 42'));
    await tester.pump();

    expect(filtered, 'UserId=42');
  });
}