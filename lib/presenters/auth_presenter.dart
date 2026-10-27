import '../models/auth_model.dart';

class AuthPresenter {
  //AuthPresenter initial code, copied from the homework tracker.
  final AuthModel _model = AuthModel();

  Future<String?> login(String email, String password) async {
    return _model.login(email, password);
  }
  Future<String?> signUp(String email, String password) async {
    return _model.signUp(email, password);
  }
  Future<void> logout() => _model.signOut();
  Stream authStateChanges() => _model.authStateChanges();
  
  final AuthModel _model = AuthModel();

  Future<String?> login(String email, String password) {
    return _model.login(email, password);
  }
  Future<String?> signUp(String email, String password) {
    return _model.signUp(email, password);
  }
  Future<void> logout() => _model.signOut();

  Stream authStateChanges() => _model.authStateChanges();

  String? getCurrentUserEmail() => _model.currentUser?.email;
}