// lib/features/goals/firestore_goals_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'goals_repository.dart';
import '../../models/goal_model.dart';

class FirestoreGoalsRepository implements GoalsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId {
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
    // (You will need to write a query here that sums up the miles from the past 7 days)
    // double recentMilesRan = await _calculateWeeklyMilesFromWorkouts();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MetricGoal(
        id: doc.id,
        title: data['title'] ?? '',
        targetMiles: (data['targetMiles'] as num?)?.toDouble() ?? 0.0,
        currentMiles:
            0.0, // Replace with your aggregated workout data calculation
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
}
