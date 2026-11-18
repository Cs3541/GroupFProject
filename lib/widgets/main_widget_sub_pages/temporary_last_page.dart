//This is a temporary placeholder page that we can determine the purpose of later
// whenever we decide on its purpose, rename class Name as well as file name
// and its respective file path within main_widget.dart

import 'package:flutter/material.dart';

import '../progress_graph.dart';

class StrengthPlaceholder extends StatelessWidget {
  const StrengthPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProgressGraph(
      title: 'Strength progress',
      summary: '130 lb',
      subtitle: 'Bench press · 8 reps per set',
      values: [115, 115, 120, 120, 125, 125, 130],
      labels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
      color: Colors.teal,
      minY: 100,
      maxY: 140,
      yInterval: 10,
    );
  }
}