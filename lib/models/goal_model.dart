import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exercise_log_model.dart';

// #########################
// -------- Models ---------
// #########################

// -- Pure Models for goals --

// Goal model contract
abstract class Goal {
  final String id;
  final String title;

  Goal({required this.id, required this.title});

  bool get isCompleted;
}

// Concrete Metric goal implementation
// e.g. run 10 miles, benchpress 200 pounds
class MetricGoal extends Goal {
  final String libraryExerciseId;
  final double targetValue;
  final double currentValue;
  final String unit;

  MetricGoal({
    required super.id,
    required this.libraryExerciseId,
    required super.title,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
  });

  @override
  bool get isCompleted => currentValue >= targetValue;
}

// Concrete Habit goal implementation
// e.g. Run once a week, Walk 10,000 steps a day
class HabitGoal extends Goal {
  @override
  final bool isCompleted;
  final String frequency;
  final DateTime? lastCompletedDate;

  HabitGoal({
    required super.id,
    required super.title,
    this.isCompleted = false,
    required this.frequency,
    required this.lastCompletedDate,
  });
}

// #####################################
// ---------- Repositories -------------
// #####################################

// --- Abstract Repository contract ---
abstract class GoalsRepository {
  Future<List<MetricGoal>> fetchMetricGoals();
  Future<List<HabitGoal>> fetchHabitGoals();
  Future<void> updateHabitStatus(String id, bool isCompleted);

  Future<String> addMetricGoal(
    String libraryExerciseId,
    String title,
    double targetValue,
    String unit,
  );
  Future<String> addHabitGoal(String title, String frequency);

  Future<void> deleteMetricGoal(String id);
  Future<void> deleteHabitGoal(String id);
}

// --- Concrete Firebase repository ---
// Handles ALL database logic to add / remove / update / fetch goals to the firestore database.
class FirestoreGoalsRepository implements GoalsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FirestoreExerciseLogRepository _logRepo;

  FirestoreGoalsRepository(this._logRepo);

  String get _userId {
    // return 'debug_test_user_123';

    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  CollectionReference get _goalsRef =>
      _firestore.collection('users').doc(_userId).collection('goals');

  @override
  Future<List<MetricGoal>> fetchMetricGoals() async {
    final snapshot = await _goalsRef.where('type', isEqualTo: 'metric').get();

    final recentLogs = await _logRepo.getLogsSince(
      DateTime.now().subtract(const Duration(days: 7)),
    );

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final libraryExerciseId = data['libraryExerciseId'] as String? ?? '';
      final unit = data['unit'] as String? ?? 'lbs';

      return MetricGoal(
        id: doc.id,
        libraryExerciseId: libraryExerciseId,
        title: data['title'] as String? ?? '',
        targetValue: (data['targetValue'] as num?)?.toDouble() ?? 0.0,
        currentValue: _calculateWeeklyProgress(
          libraryExerciseId,
          unit,
          recentLogs,
        ),
        unit: unit,
      );
    }).toList();
  }

  double _calculateWeeklyProgress(
    String libraryExerciseId,
    String unit,
    List<ExerciseLog> recentLogs,
  ) {
    final matching = recentLogs.where(
      (log) => log.libraryExerciseId == libraryExerciseId,
    );

    final normalizedUnit = unit.trim().toLowerCase();
    double total = 0.0;

    for (final log in matching) {
      if (normalizedUnit == 'reps' || normalizedUnit == 'rep') {
        total += (log.reps ?? 0) * (log.sets ?? 1);
      } else if (normalizedUnit == 'sets' || normalizedUnit == 'set') {
        total += (log.sets ?? 0);
      } else if (normalizedUnit == 'miles' ||
          normalizedUnit == 'km' ||
          normalizedUnit == 'distance') {
        total += (log.distance ?? 0.0);
      } else if (normalizedUnit == 'mins' ||
          normalizedUnit == 'minutes' ||
          normalizedUnit == 'min') {
        total += (log.durationMinutes ?? 0.0);
      } else {
        // Weight / volume units (lbs, kg): total volume = sets * reps * weight
        final sets = log.sets ?? 1;
        final reps = log.reps ?? 1;
        total += (log.weight ?? 0.0) * sets * reps;
      }
    }
    return total;
  }

  @override
  Future<List<HabitGoal>> fetchHabitGoals() async {
    final snapshot = await _goalsRef.where('type', isEqualTo: 'habit').get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      DateTime? lastCompletedDate = (data['lastCompletedDate'] as Timestamp?)
          ?.toDate();
      String frequency = data['frequency'] as String? ?? 'daily';
      bool isCompleted = data['isCompleted'] ?? false;

      if (isCompleted && lastCompletedDate != null) {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );

        final bool isExpired =
            (frequency == 'daily' &&
                lastCompletedDate.isBefore(startOfToday)) ||
            (frequency == 'weekly' && lastCompletedDate.isBefore(startOfWeek));

        if (isExpired) {
          isCompleted = false;
          lastCompletedDate = null;
          doc.reference.update({
            'isCompleted': false,
            'lastCompletedDate': null,
          });
        }
      }
      return HabitGoal(
        id: doc.id,
        title: data['title'] ?? '',
        lastCompletedDate: lastCompletedDate,
        frequency: frequency,
        isCompleted: isCompleted,
      );
    }).toList();
  }

  @override
  Future<void> updateHabitStatus(String id, bool isCompleted) async {
    await _goalsRef.doc(id).update({
      'isCompleted': isCompleted,
      'lastCompletedDate': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  @override
  Future<String> addMetricGoal(
    String libraryExerciseId,
    String title,
    double targetValue,
    String unit,
  ) async {
    final docRef = await _goalsRef.add({
      'libraryExerciseId': libraryExerciseId,
      'type': 'metric',
      'title': title,
      'targetValue': targetValue,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<String> addHabitGoal(String title, String frequency) async {
    final docRef = await _goalsRef.add({
      'type': 'habit',
      'title': title,
      'isCompleted': false,
      'frequency': frequency,
      'lastCompletedDate': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<void> deleteMetricGoal(String id) async {
    try {
      await _goalsRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete metric goal: $e');
    }
  }

  @override
  Future<void> deleteHabitGoal(String id) async {
    try {
      await _goalsRef.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete habit goal: $e');
    }
  }
}

// --- Mock Repository ---
// Lets the app test goals without direct connection to the actual firestore database
class MockGoalsRepository implements GoalsRepository {
  @override
  Future<List<MetricGoal>> fetchMetricGoals() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network lag
    return [
      MetricGoal(
        id: 'm1',
        libraryExerciseId: 'Barbell_Bench_Press_-_Medium_Grip',
        title: 'Barbell Bench Press - Medium Grip',
        targetValue: 5000.0,
        currentValue: 2750.0,
        unit: 'lbs',
      ),
      MetricGoal(
        id: 'm2',
        libraryExerciseId: '3_4_Sit-Up',
        title: '3/4 Sit-Up',
        targetValue: 100.0,
        currentValue: 100.0,
        unit: 'reps',
      ),
    ];
  }

  @override
  Future<List<HabitGoal>> fetchHabitGoals() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      HabitGoal(
        id: 'h1',
        title: 'Did I work out 3 times this week?',
        isCompleted: true,
        frequency: 'weekly',
        lastCompletedDate: DateTime.now(),
      ),
      HabitGoal(
        id: 'h2',
        title: 'Stretch for 10 minutes daily',
        isCompleted: false,
        frequency: 'daily',
        lastCompletedDate: null,
      ),
    ];
  }

  @override
  Future<void> updateHabitStatus(String id, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String> addMetricGoal(
    String libraryExerciseId,
    String title,
    double targetValue,
    String unit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_metric_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addHabitGoal(String title, String frequency) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_habit_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> deleteMetricGoal(String id) async =>
      await Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<void> deleteHabitGoal(String id) async =>
      await Future.delayed(const Duration(milliseconds: 500));
}
