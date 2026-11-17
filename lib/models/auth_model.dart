import 'package:firebase_auth/firebase_auth.dart';
import 'profile_setup_model.dart';

class AuthModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password) async {
    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Unable to create your account.';
    } catch (_) {
      return 'Unable to create your account. Please try again.';
    }

    final user = credential.user;

    if (user == null) {
      return 'Account creation did not return a user.';
    }

    try {
      await ProfileSetupModel().initializeProfile(user.uid);
    } catch (_) {
      // The Authentication account already exists.
      // The profile form can recover by saving the missing document.
      return 'Your account was created. Finish profile setup to continue.';
    }

    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}