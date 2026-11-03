import 'goals_repository.dart';
import '../../core/models/goal_model.dart';

class MockGoalsRepository implements GoalsRepository {
  @override
  Future<List<MetricGoal>> fetchMetricGoals() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network lag
    return [
      MetricGoal(
        id: 'm1',
        title: 'Run 15 miles per week',
        targetMiles: 15.0,
        currentMiles: 8.5,
      ),
      MetricGoal(
        id: 'm2',
        title: 'Cycle 50 miles per week',
        targetMiles: 50.0,
        currentMiles: 50.0,
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
}
