import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// this is some new items that have been added to show individual excersizes within the workout. 
class Exercise {
  String name;
  bool isCompleted;


  Exercise({
    required this.name,
    this.isCompleted = false,

  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
    };
  }
}
// end
class Workout {
  String? id;
  String workoutType;
  int duration;
  int? reps;
  int? weight;
  bool isCompleted;
  // new section
  String? workoutGroup;
  List<Exercise> exercises;
  int likes;

  Workout({
    this.id,
    required this.workoutType,
    required this.duration,
    this.reps,
    this.weight,
    this.isCompleted = false,
    this.workoutGroup,
    this.exercises = const [],
    this.likes = 0,
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

      // new stuff
      final exercisesData = data['exercises'] as List?;
      final exercises = exercisesData?.map((exerciseData){
        final exerciseMap = Map<String, dynamic>.from(exerciseData as Map);

        return Exercise(
          name: exerciseMap['name'] ?? '',
          isCompleted: exerciseMap['isCompleted'] ?? false,
        );
      }).toList();

      //end new 
      return Workout(
        id: doc.id,
        workoutType: data['workoutType'] ?? '',
        duration: data['duration'] ?? 0,
        reps: data['reps'],
        weight: data['weight'],
        isCompleted: data['isCompleted'] ?? false,

        // new section
        workoutGroup: data['workoutGroup'],
        exercises: exercises ?? [],
        likes: data['likes'] ?? 0,
        // end new section
      );
    }).toList();
  }
// edited to add workout groups and exercise names. 
  static Future<String?> addWorkout(String workoutType, int duration, {String? workoutGroup, List<String> exerciseNames = const[],}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final exercises = exerciseNames
        .where((name) => name.isNotEmpty)
        .map((name) => Exercise(name: name.trim()).toMap())
        .toList();

    final newDocRef = await _userWorkoutsRef(userId).add({
      'workoutType': workoutType,
      'duration': duration,
      'reps': 0,
      'weight': 0,
      'isCompleted': false,
      'workoutGroup': workoutGroup,
      'exercises' : exercises,
      'likes': 0,
    });

    return newDocRef.id;
  }

    // testing with sample workouts since cant log in yet.
  static Future<List<Workout>> fetchSampleWorkouts() async {
  await Future.delayed(const Duration(seconds: 1));


  return [
    Workout(
      id: 'w1',
      workoutType: 'Upper Body Workout',
      duration: 45 ,
      workoutGroup: 'chest',
      exercises: [
        Exercise(name: 'Bench Press'),
        Exercise(name: 'Push Ups'),
        Exercise(name: 'Pull Ups'),
      ],
      likes: 120000,
    ),
  ];
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

  //new thing to save the completion status of individual exercises within a workout
  static Future<void> updateExerciseStatus(
    String workoutId,
    List<Exercise> exercises,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final exerciseData = exercises.map((exercise) => exercise.toMap()).toList();
    await _userWorkoutsRef(userId).doc(workoutId).update({'exercises': exerciseData});
  }

  //new likes section
  static Future<void> updateLikes(String workoutId, int likes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _userWorkoutsRef(userId).doc(workoutId).update({'likes': likes});
  }
// end
  static Future<void> deleteWorkout(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _userWorkoutsRef(userId).doc(id).delete();
  }
}
