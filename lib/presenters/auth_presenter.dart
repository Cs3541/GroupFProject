import '../models/auth_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPresenter {
  final AuthModel _model = AuthModel();

  Future<String?> login(String email, String password) {
    return _model.login(email, password);
  }
  Future<String?> signUp(String email, String password) {
    return _model.signUp(email, password);
  }
  Future<void> logout() => _model.signOut();

  Stream<User?> authStateChanges() => _model.authStateChanges();

  String? getCurrentUserEmail() => _model.currentUser?.email;
}
