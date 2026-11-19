import 'package:fallguys_fitness_app/models/exercise_log_model.dart';
import 'package:fallguys_fitness_app/models/goal_model.dart';
import 'package:fallguys_fitness_app/models/workout_model.dart';

import '../views/goals_view.dart';

// Processes the request, talks to the Model to fetch or update data if needed, and applies business rules
class GoalsPresenter {
  final GoalsView _view;
  final GoalsRepository _goalsRepository;
  final ExerciseLogRepository _workoutRepository;

  List<MetricGoal> _metricGoals = [];
  List<HabitGoal> _habitGoals = [];
  List<LibraryExercise> _exercises = [];

  GoalsPresenter(this._view, this._goalsRepository, this._workoutRepository);

  Future<void> loadGoals() async {
    _view.showLoading();
    try {
      // Fetch both goal types concurrently rather than waiting for one after the other
      final results = await Future.wait([
        _goalsRepository.fetchMetricGoals(),
        _goalsRepository.fetchHabitGoals(),
        _workoutRepository.getExerciseLibrary(),
      ]);

      _metricGoals = results[0] as List<MetricGoal>;
      _habitGoals = results[1] as List<HabitGoal>;
      _exercises = results[2] as List<LibraryExercise>;

      _view.displayMetricGoals(_metricGoals);
      _view.displayAchievementGoals(_habitGoals);
      _view.displayExerciseLibrary(_exercises);
    } catch (e) {
      _view.showError("Failed to load goals. $e");
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
      frequency: targetGoal.frequency,
      lastCompletedDate: newValue ? DateTime.now() : null,
    );
    _view.displayAchievementGoals(_habitGoals);

    // network request
    try {
      await _goalsRepository.updateHabitStatus(id, newValue);
    } catch (e) {
      // rollback on failure
      _habitGoals[index] = targetGoal;
      _view.displayAchievementGoals(_habitGoals);
      _view.showError("Network error: Failed to update goal.");
    }
  }

  Future<void> addMetricGoal(
    String libraryExerciseId,
    String title,
    double targetValue,
    String unit,
  ) async {
    _view.showLoading();
    try {
      final newId = await _goalsRepository.addMetricGoal(
        libraryExerciseId,
        title,
        targetValue,
        unit,
      );
      _metricGoals.add(
        MetricGoal(
          id: newId,
          libraryExerciseId: libraryExerciseId,
          title: title,
          targetValue: targetValue,
          unit: unit,
        ),
      );
      loadGoals(); // TOOD: make this query for updates to avoid the screen loading after every added goal.
      _view.displayMetricGoals(_metricGoals);
    } catch (e) {
      _view.showError("Failed to save metric goal.");
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> addHabitGoal(String title, String frequency) async {
    _view.showLoading();
    try {
      final newId = await _goalsRepository.addHabitGoal(title, frequency);
      _habitGoals.add(
        HabitGoal(
          id: newId,
          title: title,
          isCompleted: false,
          frequency: frequency,
          lastCompletedDate: null,
        ),
      );
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
        await _goalsRepository.deleteMetricGoal(id);
      } else {
        _habitGoals.removeWhere((g) => g.id == id);
        _view.displayAchievementGoals(_habitGoals);
        await _goalsRepository.deleteHabitGoal(id);
      }
    } catch (e) {
      _view.showError("Failed to delete goal. Please try again.");
      loadGoals(); // Rollback by reloading from the source of truth
    }
  }
}
