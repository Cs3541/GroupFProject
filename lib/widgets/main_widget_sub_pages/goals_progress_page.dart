//This will have to call on the goals presenter
// Carson this is where you will define and create
// the graphs related to goals progress then build it within this page


import 'package:flutter/material.dart';

import '../progress_graph.dart';

class GoalsProgressPage extends StatelessWidget {
  const GoalsProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProgressGraph(
      title: 'Body weight',
      summary: '80.5 kg',
      subtitle: 'Weekly measurements',
      values: [82, 81.8, 81.9, 81.4, 81.2, 80.8, 80.5],
      labels: ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
      color: Colors.purple,
      minY: 79,
      maxY: 83,
      yInterval: 1,
    );
  }
}