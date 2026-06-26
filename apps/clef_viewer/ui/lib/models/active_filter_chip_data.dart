import 'package:flutter/material.dart';

class ActiveFilterChipData {
  final String id;
  final String label;
  final VoidCallback onRemove;

  const ActiveFilterChipData({
    required this.id,
    required this.label,
    required this.onRemove,
  });
}