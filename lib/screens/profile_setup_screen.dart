import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveProfile({
  required String name,
  required double heightCm,
  required double weightKg,
  required String preferredUnits,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw StateError('Must be signed in to save a profile');
  }

  if (name.trim().isEmpty ||
  !heightCm.isFinite || heightCm <= 0 ||
  !weightKg.isFinite || weightKg <= 0 ||
  !{'metric', 'imperial'}.contains(preferredUnits)) {
    throw ArgumentError('Enter valid profile information.');
  }

  await FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .set({
    'name': name.trim(),
    'heightCm': heightCm,
    'weightKg': weightKg,
    'preferredUnits': preferredUnits,
    'profileComplete': true,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}