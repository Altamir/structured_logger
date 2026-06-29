import 'package:clef_viewer_ui/widgets/stream_pause_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the AppBar pause wiring from ClefViewerApp without network/SSE.
class _TestViewerShell extends StatefulWidget {
  const _TestViewerShell();

  @override
  State<_TestViewerShell> createState() => _TestViewerShellState();
}

class _TestViewerShellState extends State<_TestViewerShell> {
  final _viewerKey = GlobalKey<_MockViewerPageState>();
  bool _streamPaused = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            StreamPauseIconButton(
              isPaused: _streamPaused,
              onPressed: () => _viewerKey.currentState?.togglePause(),
            ),
          ],
        ),
        body: _MockViewerPage(
          key: _viewerKey,
          onPausedChanged: (paused) => setState(() => _streamPaused = paused),
        ),
      ),
    );
  }
}

class _MockViewerPage extends StatefulWidget {
  final ValueChanged<bool>? onPausedChanged;

  const _MockViewerPage({super.key, this.onPausedChanged});

  @override
  State<_MockViewerPage> createState() => _MockViewerPageState();
}

class _MockViewerPageState extends State<_MockViewerPage> {
  bool _paused = false;

  void togglePause() {
    setState(() => _paused = !_paused);
    widget.onPausedChanged?.call(_paused);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets('pause button visible in app bar', (tester) async {
    await tester.pumpWidget(const _TestViewerShell());

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('pause button toggles to play icon', (tester) async {
    await tester.pumpWidget(const _TestViewerShell());

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byTooltip('Retomar'), findsOneWidget);
  });
}