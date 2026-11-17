import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_setup_model.dart';

class ProfileSetupPresenter {
  final ProfileSetupModel _model = ProfileSetupModel();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _model.watchProfile(uid);
  }
  Future<Map<String, dynamic>?> getProfile(String uid) {
    return _model.getProfile(uid);
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required double heightCm,
    required double weightKg,
  }) {
    return _model.saveProfile(
      uid: uid,
      name: name,
      heightCm: heightCm,
      weightKg: weightKg,
    );
  }
}