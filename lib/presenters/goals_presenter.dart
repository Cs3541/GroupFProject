import 'package:fallguys_fitness_app/models/goal_model.dart';

import '../views/goals_view.dart';
import '../repositories/goals_repository.dart';

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

  Future<void> addMetricGoal(
    String title,
    double targetValue,
    String unit,
  ) async {
    _view.showLoading();
    try {
      final newId = await _repository.addMetricGoal(title, targetValue, unit);
      _metricGoals.add(
        MetricGoal(
          id: newId,
          title: title,
          targetValue: targetValue,
          currentValue: 0.0,
          unit: unit,
        ),
      );
      _view.displayMetricGoals(_metricGoals);
    } catch (e) {
      _view.showError("Failed to save distance goal.");
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> addHabitGoal(String title) async {
    _view.showLoading();
    try {
      final newId = await _repository.addHabitGoal(title);
      _habitGoals.add(HabitGoal(id: newId, title: title, isCompleted: false));
      _view.displayAchievementGoals(_habitGoals);
    } catch (e) {
      _view.showError("Failed to save habit goal.");
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteGoal(String id, {required bool isMetric}) async {
    try {
      if (isMetric) {
        // Optimistic local update
        _metricGoals.removeWhere((g) => g.id == id);
        _view.displayMetricGoals(_metricGoals);
        // Network call
        await _repository.deleteMetricGoal(id);
      } else {
        _habitGoals.removeWhere((g) => g.id == id);
        _view.displayAchievementGoals(_habitGoals);
        await _repository.deleteHabitGoal(id);
      }
    } catch (e) {
      _view.showError("Failed to delete goal. Please try again.");
      loadGoals(); // Rollback by reloading from the source of truth
    }
  }
}
