import 'package:firebase_database/firebase_database.dart';

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

  static final _db = FireDatabase.instance.ref();
  static final _auth = FirebaseAuth.instance;

  static Future<List<Workout>> fetchWorkout() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _db.child('workouts/$userId').get();
    final List<Workout> workouts = [];

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        workouts.add(
          Workout(
            id: key,
            workoutType: value['workoutType'],
            duration: value['duration'],
            reps: value['reps'],
            weight: value['weight'],
            isCompleted: value['completed'],
          ),
        );
      });
    }
    return workouts;
  }

  static Future<String?> addWorkout(
    String workoutType,
    int duration,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final newRef = _db.child('workouts/$userId').push();

    await newRef.set({
      'workoutType': workoutType,
      'duration': duration,
      'reps': 0,
      'weight': 0,
      'isCompleted': false
    });

    return newRef.key;
  }

  static Future<void> updateCompletionStatus(
    int index,
    List<Workout> currentWorkouts,
  ) async {
    final userId = _auth.currentUser?.uid;

    if (userId == null || index < 0 || index >= currentWorkouts.length) {
      return;
    }

    final workout = currentWorkouts[index];
    if (workout.id == null) return;

    final ref = _db.child('workouts/$userId/${workout.id}');
    final updatedStatus = !workout.isCompleted;

    await ref.update({'isCompleted': updatedStatus});
  }

  static Future<void> deleteWorkout(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _db.child('workouts/$userId/$id').remove();
  }
}


