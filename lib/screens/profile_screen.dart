import 'package:flutter/material.dart';
import '../presenters/auth_presenter.dart';
import '../screens/profile_setup_screen.dart';


class ProfileScreen extends StatelessWidget {
  final AuthPresenter _presenter = AuthPresenter();

  ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await _presenter.logout();
  }
  Future<void> _editProfile(BuildContext context) async {
    final uid = _presenter.getCurrentUserId();
    if (uid == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfileSetupScreen(
          uid: uid,
          isEditing: true,
        ),
      ),
    );

    if (!context.mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _presenter.getCurrentUserEmail() ?? 'Unknown User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.purple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
            ),
            const SizedBox(height: 40),
               ElevatedButton.icon(
                onPressed: () => _editProfile(context),
                icon: const Icon(Icons.info),
                label: const Text('Change User Information'),
                style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.red,
              )
              ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
                onPressed: () =>  _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.redAccent,
              )
            ),
          ],
        ),
      ),
    );
  }
}