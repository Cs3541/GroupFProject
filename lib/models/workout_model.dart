import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// this is some new items that have been added to show individual excersizes within the workout. 
class Exercise {
  String name;
  bool isCompleted;
  // How long this exercise should take, in seconds. Null means no timer.
  int? durationSeconds;

  Exercise({
    required this.name,
    this.isCompleted = false,
    this.durationSeconds,
  });

  // Builds an Exercise from text like "Pushups:60" (60 second timer) or "Plank" (no timer).
  factory Exercise.fromInput(String input) {
    final entry = input.trim();
    final colon = entry.lastIndexOf(':');
    if (colon != -1) {
      final name = entry.substring(0, colon).trim();
      final seconds = int.tryParse(entry.substring(colon + 1).trim());
      if (name.isNotEmpty && seconds != null && seconds > 0) {
        return Exercise(name: name, durationSeconds: seconds);
      }
    }
    return Exercise(name: entry);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'durationSeconds': durationSeconds,
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
          // older saved exercises won't have this field, so it stays null
          durationSeconds: (exerciseMap['durationSeconds'] as num?)?.toInt(),
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

    // each name can include a timer, e.g. "Pushups:60"
    final exercises = exerciseNames
        .where((name) => name.trim().isNotEmpty)
        .map((name) => Exercise.fromInput(name).toMap())
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

// ---------------- exercise library ----------------
// An exercise from the shared 'exercises' collection (the library),
// not to be confused with Exercise above, which is one entry inside a routine.
class LibraryExercise {
  final String id;
  final String name;
  final String nameLower;
  final List<String> searchTokens;
  final List<String> images;
  final List<String> instructions;
  final List<String> primaryMuscles;
  final String? equipment;
  final String? level;
  final String? category;

  LibraryExercise({
    required this.id,
    required this.name,
    required this.nameLower,
    this.searchTokens = const [],
    this.images = const [],
    this.instructions = const [],
    this.primaryMuscles = const [],
    this.equipment,
    this.level,
    this.category,
  });

  static final _firestore = FirebaseFirestore.instance;

  // Some library documents have missing fields or empty arrays, so every field has a safe default.
  factory LibraryExercise.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final name = (data['name'] as String?) ?? doc.id.replaceAll('_', ' ');

    return LibraryExercise(
      id: doc.id,
      name: name,
      nameLower: (data['nameLower'] as String?) ?? name.toLowerCase(),
      searchTokens: _stringList(data['searchTokens']),
      images: _stringList(data['images']),
      instructions: _stringList(data['instructions']),
      primaryMuscles: _stringList(data['primaryMuscles']),
      equipment: data['equipment'] as String?,
      level: data['level'] as String?,
      category: data['category'] as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  // Reads the whole library collection, sorted alphabetically by name.
  static Future<List<LibraryExercise>> fetchLibrary() async {
    final snapshot = await _firestore.collection('exercises').get();
    final library = snapshot.docs.map(LibraryExercise.fromFirestore).toList();
    library.sort((a, b) => a.nameLower.compareTo(b.nameLower));
    return library;
  }

  // Splits text the same way the search tokens were made: lowercase, broken on anything
  // that isn't a letter or digit. "3/4 Sit-Up" -> [3, 4, sit, up]
  static List<String> _words(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  // True when every typed word matches a search token, or (because the tokens aren't
  // exhaustive) is the start of a word in the name. An empty query matches everything.
  bool matches(String query) {
    final typedWords = _words(query);
    if (typedWords.isEmpty) return true;

    final nameWords = _words(nameLower);
    return typedWords.every((typed) =>
        searchTokens.contains(typed) ||
        nameWords.any((word) => word.startsWith(typed)));
  }
}
// end exercise library
