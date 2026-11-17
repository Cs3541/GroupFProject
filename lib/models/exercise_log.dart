import 'workout_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseLog {
  final String? id;
  final String libraryExerciseId;
  final String exerciseName;
  final double value;
  final String unit;
  final int reps;
  final int sets;
  final DateTime timestamp;

  ExerciseLog({
    this.id,
    required this.libraryExerciseId,
    required this.exerciseName,
    required this.value,
    required this.unit,
    this.reps = 1,
    this.sets = 1,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'libraryExerciseId': libraryExerciseId,
      'exerciseName': exerciseName,
      'value': value,
      'unit': unit,
      'reps': reps,
      'sets': sets,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ExerciseLog.fromMap(String documentId, Map<String, dynamic> map) {
    return ExerciseLog(
      id: documentId,
      libraryExerciseId: map['libraryExerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'lbs',
      reps: (map['reps'] as num?)?.toInt() ?? 1,
      sets: (map['sets'] as num?)?.toInt() ?? 1,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

abstract class WorkoutRepository {
  Future<List<LibraryExercise>> getExerciseLibrary();
  Future<List<ExerciseLog>> getExerciseHistory(String libraryExerciseId);
  Future<String> addExerciseLog(ExerciseLog log);
  Future<void> deleteExerciseLog(String logId);
}

class FirestoreWorkoutRepository implements WorkoutRepository {
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
    final snapshot = await _firestore.collection('exercises').get();
    final library = snapshot.docs.map(LibraryExercise.fromFirestore).toList();
    library.sort((a, b) => a.nameLower.compareTo(b.nameLower));
    return library;
  }

  @override
  Future<List<ExerciseLog>> getExerciseHistory(String libraryExerciseId) async {
    final snapshot = await _logsRef
        .where('libraryExerciseId', isEqualTo: libraryExerciseId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              ExerciseLog.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
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
}
