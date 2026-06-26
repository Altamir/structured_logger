import 'package:flutter/material.dart';

class LevelBadge extends StatelessWidget {
  final String level;

  const LevelBadge({super.key, required this.level});

  Color get _color {
    final normalized = level.toLowerCase();
    if (normalized.contains('error') || normalized.contains('fatal')) {
      return Colors.red.shade700;
    }
    if (normalized.contains('warn')) {
      return Colors.amber.shade800;
    }
    if (normalized.contains('debug') || normalized.contains('verbose')) {
      return Colors.blueGrey;
    }
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}