import 'package:clef_viewer_ui/widgets/stream_pause_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows pause icon when streaming', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamPauseIconButton(
            isPaused: false,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byTooltip('Pausar'), findsOneWidget);
  });

  testWidgets('shows play icon when paused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamPauseIconButton(
            isPaused: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byTooltip('Retomar'), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamPauseIconButton(
            isPaused: false,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(StreamPauseIconButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}