import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  String? id;
  String workoutType;
  int duration;
  int? reps;
  int? weight;
  bool isCompleted;

  Workout({
    this.id,
    required this.workoutType,
    required this.duration,
    this.reps,
    this.weight,
    this.isCompleted = false,
  });

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Helper to get the correct collection path
  static CollectionReference _userWorkoutsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('workouts');
  }

  static Future<List<Workout>> fetchWorkout() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _userWorkoutsRef(userId).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Workout(
        id: doc.id,
        workoutType: data['workoutType'] ?? '',
        duration: data['duration'] ?? 0,
        reps: data['reps'],
        weight: data['weight'],
        isCompleted: data['isCompleted'] ?? false,
      );
    }).toList();
  }

  static Future<String?> addWorkout(String workoutType, int duration) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final newDocRef = await _userWorkoutsRef(userId).add({
      'workoutType': workoutType,
      'duration': duration,
      'reps': 0,
      'weight': 0,
      'isCompleted': false,
    });

    return newDocRef.id;
  }

  // Refactored to accept just the ID and the new status to decouple from UI state
  static Future<void> updateCompletionStatus(
    String workoutId,
    bool isCurrentlyCompleted,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final docRef = _userWorkoutsRef(userId).doc(workoutId);

    await docRef.update({'isCompleted': !isCurrentlyCompleted});
  }

  static Future<void> deleteWorkout(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _userWorkoutsRef(userId).doc(id).delete();
  }
}
