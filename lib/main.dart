import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FitByteApp());
}

class FitByteApp extends StatelessWidget {
  const FitByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitByteApp Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  } // MaterialApp
}
