import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// #########################
// -------- Models ---------
// #########################

// -- Pure Models for goals --

// Goal model contract
abstract class Goal {
  String get id;
  String get title;
  bool get isCompleted;
}

// Concrete Metric goal implementation
// e.g. run 10 miles, benchpress 200 pounds
class MetricGoal implements Goal {
  @override
  final String id;
  @override
  final String title;

  final double targetValue;
  final double currentValue;
  final String unit;

  MetricGoal({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    this.unit = '',
  });

  @override
  bool get isCompleted => currentValue >= targetValue;
}

// Concrete Habit goal implementation
// e.g. Run once a week, Walk 10,000 steps a day
class HabitGoal implements Goal {
  @override
  final String id;
  @override
  final String title;
  @override
  final bool isCompleted;

  HabitGoal({required this.id, required this.title, this.isCompleted = false});
}

// #####################################
// ---------- Repositories -------------
// #####################################

// --- Abstract Repository contract ---
abstract class GoalsRepository {
  Future<List<MetricGoal>> fetchMetricGoals();
  Future<List<HabitGoal>> fetchHabitGoals();
  Future<void> updateHabitStatus(String id, bool isCompleted);

  Future<String> addMetricGoal(String title, double targetMiles, String unit);
  Future<String> addHabitGoal(String title);

  Future<void> deleteMetricGoal(String id);
  Future<void> deleteHabitGoal(String id);
}

// Concrete Firebase repository
// Handles ALL database logic to add / remove / update / fetch goals to the firestore database.
class FirestoreGoalsRepository implements GoalsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
    // 1. Fetch the user's target goals
    final snapshot = await _goalsRef.where('type', isEqualTo: 'metric').get();

    // 2. Aggregate actual distance from the workouts collection
    // TODO: write a query here that sums up the miles from the past 7 days
    // double recentMilesRan = await _calculateWeeklyMilesFromWorkouts();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MetricGoal(
        id: doc.id,
        title: data['title'] ?? '',
        targetValue: (data['targetMiles'] as num?)?.toDouble() ?? 0.0,
        currentValue:
            0.0, // TODO: Replace with aggregated workout data calculation
      );
    }).toList();
  }

  @override
  Future<List<HabitGoal>> fetchHabitGoals() async {
    final snapshot = await _goalsRef.where('type', isEqualTo: 'habit').get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return HabitGoal(
        id: doc.id,
        title: data['title'] ?? '',
        isCompleted: data['isCompleted'] ?? false,
      );
    }).toList();
  }

  @override
  Future<void> updateHabitStatus(String id, bool isCompleted) async {
    await _goalsRef.doc(id).update({'isCompleted': isCompleted});
  }

  @override
  Future<String> addMetricGoal(
    String title,
    double targetMiles,
    String unit,
  ) async {
    final docRef = await _goalsRef.add({
      'type': 'metric',
      'title': title,
      'targetMiles': targetMiles,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<String> addHabitGoal(String title) async {
    final docRef = await _goalsRef.add({
      'type': 'habit',
      'title': title,
      'isCompleted': false,
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
        title: 'Run 15 miles per week',
        targetValue: 15.0,
        currentValue: 8.5,
      ),
      MetricGoal(
        id: 'm2',
        title: 'Cycle 50 miles per week',
        targetValue: 50.0,
        currentValue: 50.0,
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
      ),
      HabitGoal(
        id: 'h2',
        title: 'Stretch for 10 minutes daily',
        isCompleted: false,
      ),
    ];
  }

  @override
  Future<void> updateHabitStatus(String id, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a mock, you just return success. The Presenter handles the local state update.
  }

  @override
  Future<String> addMetricGoal(
    String title,
    double targetMiles,
    String unit,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    // Generate a fake unique ID
    return 'mock_metric_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addHabitGoal(String title) async {
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
