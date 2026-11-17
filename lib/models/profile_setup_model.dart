import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

    Future<void> initializeProfile(String uid) async {
    final ref = _profileRef(uid);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          'onboardingStatus': 'incomplete',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('The signed-in account has changed.');
    }

    final snapshot = await _profileRef(uid).get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _profileRef(uid).snapshots(includeMetadataChanges: true);
  }

    Future<void> saveProfile({
    required String uid,
    required String name,
    required double heightCm,
    required double weightKg,
  }) async {
    // 1. Check the account and validate the submitted information.
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('The signed-in account has changed.');
    }

    if (name.trim().isEmpty ||
        !heightCm.isFinite ||
        heightCm <= 0 ||
        !weightKg.isFinite ||
        weightKg <= 0) {
      throw ArgumentError('Enter valid profile information.');
    }

    final profileRef = _profileRef(uid);

    // Generate a reference without writing anything yet.
    // Automatic transaction retries will reuse this same entry ID.
    final weightEntryRef =
        profileRef.collection('bodyWeightEntries').doc();

    await _firestore.runTransaction<void>((transaction) async {
      // 2. Read the saved weight before updating the profile.
      final snapshot = await transaction.get(profileRef);

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('The signed-in account has changed.');
      }

      final storedWeight = snapshot.data()?['weightKg'];
      final previousWeight =
          storedWeight is num ? storedWeight.toDouble() : null;

      final shouldRecordWeight = previousWeight == null ||
          !previousWeight.isFinite ||
          previousWeight <= 0 ||
          previousWeight != weightKg;

      // 3. Save the current profile information.
      transaction.set(
        profileRef,
        {
          'name': name.trim(),
          'heightCm': heightCm,
          'weightKg': weightKg,
          'preferredUnits': 'metric',
          'onboardingStatus': 'complete',
          'updatedAt': FieldValue.serverTimestamp(),
          if (!snapshot.exists)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Preserve the first weight or a changed weight as history.
      if (shouldRecordWeight) {
        transaction.set(weightEntryRef, {
          'weightKg': weightKg,
          'measuredAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}