import 'package:flutter/material.dart';

import '../presenters/auth_presenter.dart';
import '../presenters/profile_setup_presenter.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.uid,
    this.isEditing = false,
  });

  final String uid;
  final bool isEditing;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _presenter = ProfileSetupPresenter();
  final _authPresenter = AuthPresenter();

  bool _loading = false;
  bool _saving = false;
  bool _signingOut = false;

  String? _loadError;
  String? _errorMessage;

  bool get _busy => _loading || _saving || _signingOut;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_busy) return;

    setState(() {
      _loading = true;
      _loadError = null;
      _errorMessage = null;
    });

    try {
      final data = await _presenter.getProfile(widget.uid);

      if (!mounted) return;

      if (data == null) {
        throw StateError('Profile not found.');
      }

      _nameController.text = data['name'] as String? ?? '';
      _heightController.text =
          (data['heightCm'] as num?)?.toString() ?? '';
      _weightController.text =
          (data['weightKg'] as num?)?.toString() ?? '';
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to load your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _validateMeasurement(String? text) {
    final value = double.tryParse(text?.trim() ?? '');

    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter a number greater than zero.';
    }

    return null;
  }

  Future<void> _save() async {
    if (_busy || _loadError != null) return;
    if (_formKey.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _presenter.saveProfile(
        uid: widget.uid,
        name: _nameController.text.trim(),
        heightCm: double.parse(_heightController.text.trim()),
        weightKg: double.parse(_weightController.text.trim()),
      );

      if (!mounted) return;

      // Editing was opened from Profile, so return there after saving.
      if (widget.isEditing &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(true);
      }

      // During initial setup, AuthGate handles the transition to Home.
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to save your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;

    setState(() {
      _signingOut = true;
      _errorMessage = null;
    });

    try {
      await _authPresenter.logout();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to sign out. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEditing
                  ? 'Update your information below.'
                  : 'Enter your information to finish account setup.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: _validateMeasurement,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: _validateMeasurement,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(
                _saving
                    ? 'Saving…'
                    : widget.isEditing
                        ? 'Save changes'
                        : 'Finish setup',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit profile' : 'Set up your profile',
        ),
        automaticallyImplyLeading: widget.isEditing,
        actions: [
          if (!widget.isEditing)
            TextButton(
              onPressed: _busy ? null : _signOut,
              child: Text(
                _signingOut ? 'Signing out…' : 'Sign out',
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
}