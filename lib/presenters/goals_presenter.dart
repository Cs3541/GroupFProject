import 'package:fallguys_fitness_app/models/goal_model.dart';

import '../views/goals_view.dart';
import '../repositories/goals/goals_repository.dart';

class GoalsPresenter {
  final GoalsView _view;
  final GoalsRepository _repository;

  List<MetricGoal> _metricGoals = [];
  List<HabitGoal> _habitGoals = [];

  GoalsPresenter(this._view, this._repository);

  Future<void> loadGoals() async {
    _view.showLoading();
    try {
      // Fetch both goal types concurrently rather than waiting for one after the other
      final results = await Future.wait([
        _repository.fetchMetricGoals(),
        _repository.fetchHabitGoals(),
      ]);

      _metricGoals = results[0] as List<MetricGoal>;
      _habitGoals = results[1] as List<HabitGoal>;

      _view.displayMetricGoals(_metricGoals);
      _view.displayAchievementGoals(_habitGoals);
    } catch (e) {
      _view.showError("Failed to load goals.");
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> toggleHabitGoal(String id, bool newValue) async {
    final index = _habitGoals.indexWhere((g) => g.id == id);
    if (index == -1) return;

    final targetGoal = _habitGoals[index];

    // optimistic Update: update the model and view immediately
    _habitGoals[index] = HabitGoal(
      id: targetGoal.id,
      title: targetGoal.title,
      isCompleted: newValue,
    );
    _view.displayAchievementGoals(_habitGoals);

    // network request
    try {
      await _repository.updateHabitStatus(id, newValue);
    } catch (e) {
      // rollback on failure
      _habitGoals[index] = targetGoal;
      _view.displayAchievementGoals(_habitGoals);
      _view.showError("Network error: Failed to update goal.");
    }
  }
}
