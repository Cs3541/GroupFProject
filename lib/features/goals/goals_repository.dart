import '../../core/models/goal_model.dart';

// could be any repository / database
abstract class GoalsRepository {
  Future<List<MetricGoal>> fetchMetricGoals();
  Future<List<HabitGoal>> fetchHabitGoals();
  Future<void> updateHabitStatus(String id, bool isCompleted);
}

// concrete implementation exists at firestore_goals_repository.dart


