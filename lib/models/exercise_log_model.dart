import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fallguys_fitness_app/views/workout_routine_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'workout_model.dart';

class ExerciseLog {
  final String id;
  final String libraryExerciseId;
  final String exerciseName;
  final String? category;
  final List<String> primaryMuscles;
  final DateTime loggedAt;
  final int? sets;
  final int? reps;
  final double? weight;
  final double? distance;
  final double? durationMinutes;

  ExerciseLog({
    required this.id,
    required this.libraryExerciseId,
    required this.exerciseName,
    this.category,
    this.primaryMuscles = const [],
    required this.loggedAt,
    this.sets,
    this.reps,
    this.weight,
    this.distance,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'libraryExerciseId': libraryExerciseId,
      'exerciseName': exerciseName,
      'category': category,
      'primaryMuscles': primaryMuscles,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'distance': distance,
      'durationMinutes': durationMinutes,
    };
  }

  factory ExerciseLog.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = data['loggedAt'];
    return ExerciseLog(
      id: doc.id,
      libraryExerciseId: (data['libraryExerciseId'] as String?) ?? '',
      exerciseName: (data['exerciseName'] as String?) ?? '',
      category: data['category'] as String?,
      primaryMuscles:
          (data['primaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      loggedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      sets: (data['sets'] as num?)?.toInt(),
      reps: (data['reps'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      distance: (data['distance'] as num?)?.toDouble(),
      durationMinutes: (data['durationMinutes'] as num?)?.toDouble(),
    );
  }
}

abstract class ExerciseLogRepository {
  Future<List<LibraryExercise>> getExerciseLibrary();
  Future<List<ExerciseLog>> getExerciseHistory(String libraryExerciseId);
  Future<String> addExerciseLog(ExerciseLog log);
  Future<void> deleteExerciseLog(String logId);
  Future<List<ExerciseLog>> getLogsSince(DateTime cutoff);
  Future<List<ExerciseLog>> getAllLogs();
}

class FirestoreExerciseLogRepository implements ExerciseLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  CollectionReference get _logsRef =>
      _firestore.collection('users').doc(_userId).collection('exercise_logs');

  @override
  Future<List<LibraryExercise>> getExerciseLibrary() async {
    return LibraryExercise.fetchLibrary();
  }

  @override
  Future<List<ExerciseLog>> getExerciseHistory(String libraryExerciseId) async {
    final snapshot = await _logsRef
        .where('libraryExerciseId', isEqualTo: libraryExerciseId)
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ExerciseLog.fromFirestore(doc)).toList();
  }

  @override
  Future<String> addExerciseLog(ExerciseLog log) async {
    final docRef = await _logsRef.add(log.toMap());
    return docRef.id;
  }

  @override
  Future<void> deleteExerciseLog(String logId) async {
    await _logsRef.doc(logId).delete();
  }

  @override
  Future<List<ExerciseLog>> getLogsSince(DateTime cutoff) async {
    final snapshot = await _logsRef
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ExerciseLog.fromFirestore(doc)).toList();
  }

  @override
  Future<List<ExerciseLog>> getAllLogs() async {
    final snapshot = await _logsRef.orderBy('loggedAt', descending: true).get();

    return snapshot.docs.map((doc) => ExerciseLog.fromFirestore(doc)).toList();
  }
}
