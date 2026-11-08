import 'package:fallguys_fitness_app/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'views/main_navigation_view.dart';
import '../views/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const FitByteApp());
}

class FitByteApp extends StatelessWidget {
  const FitByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitByte',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
