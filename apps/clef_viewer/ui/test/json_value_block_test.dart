import 'package:clef_viewer_ui/widgets/json_value_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('small JSON value renders without view-all button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JsonValueBlock(
            propertyKey: 'Payload',
            value: {'a': 1},
          ),
        ),
      ),
    );

    expect(find.text('Payload'), findsOneWidget);
    expect(find.textContaining('"a": 1'), findsOneWidget);
    expect(find.text('Ver completo'), findsNothing);
  });

  testWidgets('large JSON value shows preview and opens dialog', (tester) async {
    final largeMap = {for (var i = 0; i < 30; i++) 'key$i': i};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JsonValueBlock(
            propertyKey: 'Data',
            value: largeMap,
          ),
        ),
      ),
    );

    expect(find.text('Ver completo'), findsOneWidget);

    await tester.tap(find.text('Ver completo'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Data'), findsWidgets);
    expect(find.text('Fechar'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
  });

  testWidgets('truncate false shows full content without button', (tester) async {
    final largeMap = {for (var i = 0; i < 30; i++) 'key$i': i};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JsonValueBlock(
            propertyKey: 'Data',
            value: largeMap,
            truncate: false,
          ),
        ),
      ),
    );

    expect(find.text('Ver completo'), findsNothing);
    expect(find.textContaining('key29'), findsOneWidget);
  });
}