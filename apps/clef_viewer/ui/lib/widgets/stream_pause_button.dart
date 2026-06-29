import 'package:flutter/material.dart';

class StreamPauseIconButton extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPressed;

  const StreamPauseIconButton({
    super.key,
    required this.isPaused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isPaused ? 'Retomar' : 'Pausar',
      icon: Icon(
        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
      ),
    );
  }
}