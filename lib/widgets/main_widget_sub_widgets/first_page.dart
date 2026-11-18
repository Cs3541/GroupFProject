//Initial page for the main widget to open to
// we can rename to main page or something later
// Carson this is where you will do the first graoh you had in mind
// remember to rename class name both here and in main_widget.dart 
//when you decide on a name for this page

import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('First Page Super Cool Graph!', style: TextStyle(fontSize: 18)),
    );
  }
}