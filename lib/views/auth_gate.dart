import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../presenters/auth_presenter.dart';
import '../screens/signup_screen.dart';
import 'main_navigation_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthPresenter _presenter = AuthPresenter();

  late final Stream<User?> _authState;

  @override
  void initState() {
    super.initState();
    _authState = _presenter.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to check signin. Restart to try again.',
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const SignupScreen(),
              );
            },
          );
        }

        return MainNavigationScreen(
          key: ValueKey(user.uid),
        );
      },
    );
  }
}