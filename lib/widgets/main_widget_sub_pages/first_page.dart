//Initial page for the main widget to open to
// we can rename to main page or something later
// Carson this is where you will do the first graoh you had in mind
// remember to rename class name both here and in main_widget.dart 
//when you decide on a name for this page

import 'package:flutter/material.dart';

import '../progress_graph.dart';

class CaloriesGraph extends StatelessWidget {
  const CaloriesGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProgressGraph(
      title: 'Calories burned',
      summary: '2,220 kcal',
      subtitle: 'Total calories burned per week',
      values: [220, 340, 280, 410, 190, 360, 420],
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      color: Colors.deepOrange,
      minY: 0,
      maxY: 500,
      yInterval: 100,
      isBarChart: true,
    );
  }
}