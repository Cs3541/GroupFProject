import '../models/goal_model.dart';

// could be any repository / database
abstract class GoalsRepository {
  Future<List<MetricGoal>> fetchMetricGoals();
  Future<List<HabitGoal>> fetchHabitGoals();
  Future<void> updateHabitStatus(String id, bool isCompleted);

  Future<String> addMetricGoal(String title, double targetMiles, String unit);
  Future<String> addHabitGoal(String title);

  Future<void> deleteMetricGoal(String id);
  Future<void> deleteHabitGoal(String id);
}

// concrete implementation exists at firestore_goals_repository.dart
