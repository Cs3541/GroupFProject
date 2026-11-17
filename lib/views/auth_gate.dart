import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../presenters/auth_presenter.dart';
import '../screens/signup_screen.dart';
import 'main_navigation_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../presenters/profile_setup_presenter.dart';
import '../screens/profile_setup_screen.dart';

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

        return _ProfileGate(
          key: ValueKey(user.uid),
          uid: user.uid,
        );
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  final _presenter = ProfileSetupPresenter();
  final _authPresenter = AuthPresenter();

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;

  // Completion stays complete for this signed-in session.
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _profileStream = _presenter.watchProfile(widget.uid).where((document) {
      final status = document.data()?['onboardingStatus'];

      // A missing cached document isn't proof that the profile is missing.
      return !document.metadata.isFromCache ||
          document.metadata.hasPendingWrites ||
          status == 'complete';
    }).map((document) {
      final status = document.data()?['onboardingStatus'];

      if (status == 'complete' && !document.metadata.hasPendingWrites) {
        _completed = true;
      }

      return document;
    });
  }

  void _retry() {
    setState(_connect);
  }

  Future<void> _signOut() async {
    try {
      await _authPresenter.logout();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please retry.')),
      );
    }
  }

  Widget _statusScreen(String message, {bool loading = false}) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
              ],
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,
      builder: (context, snapshot) {
        if (_completed) {
          return const MainNavigationScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _statusScreen(
            'Loading your profile. Check your connection if this takes a while.',
            loading: true,
          );
        }

        if (snapshot.hasError) {
          return _statusScreen('Unable to load your profile.');
        }

        final document = snapshot.data;

        if (document == null) {
          return _statusScreen('Waiting for your profile.', loading: true);
        }

        final status = document.data()?['onboardingStatus'];

        if (status == null ||
            status == 'incomplete' ||
            (status == 'complete' && document.metadata.hasPendingWrites)) {
          return ProfileSetupScreen(
            key: ValueKey('setup-${widget.uid}'),
            uid: widget.uid,
          );
        }

        return _statusScreen(
          'Unable to determine whether account setup is complete.',
        );
      },
    );
  }
}