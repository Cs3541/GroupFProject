import 'package:fallguys_fitness_app/models/goal_model.dart';
import 'package:fallguys_fitness_app/models/workout_model.dart';
import 'package:flutter/material.dart';

import '../models/exercise_log_model.dart';
import '../views/exercise_log_view.dart';

class ExerciseLogPresenter {
  ExerciseLogView? _view;
  final ExerciseLogRepository _exerciseLogRepository;
  final GoalsRepository _goalsRepository;

  List<LibraryExercise> _exercises = [];
  List<MetricGoal> _goals = [];
  List<ExerciseLog> _logs = [];

  ExerciseLogPresenter(
    ExerciseLogView view,
    this._exerciseLogRepository,
    this._goalsRepository,
  ) : _view = view;

  Future<void> loadExercises() async {
    _view?.showLoading();
    try {
      final libraryFuture = _exerciseLogRepository.getExerciseLibrary();
      final goalsFuture = _goalsRepository.fetchMetricGoals();
      final logsFuture = _exerciseLogRepository.getAllLogs();

      await Future.wait([libraryFuture, goalsFuture, logsFuture]);

      _exercises = await libraryFuture;
      _goals = await goalsFuture;
      _logs = await logsFuture;

      _view?.displayExerciseLibrary(_exercises);
      _view?.displayRecentLogs(_logs);
      _view?.displayGoalSuggestions(_goals);
    } catch (e) {
      _view?.showError("Loading error: $e");
    } finally {
      _view?.hideLoading();
    }
  }

  Future<void> addExerciseLog({
    required LibraryExercise exercise,
    DateTime? loggedAt,
    int? sets,
    int? reps,
    double? weight,
    double? distance,
    double? durationMinutes,
  }) async {
    final hasValidMetric =
        (sets ?? 0) > 0 ||
        (reps ?? 0) > 0 ||
        (weight ?? 0) > 0 ||
        (distance ?? 0) > 0 ||
        (durationMinutes ?? 0) > 0;

    if (!hasValidMetric) {
      _view?.showError('Enter at least one workout metric before saving.');
      return;
    }

    final effectiveDate = loggedAt ?? DateTime.now();
    _view?.showLoading();

    try {
      final newId = await _exerciseLogRepository.addExerciseLog(
        exercise: exercise,
        loggedAt: effectiveDate,
        sets: sets,
        reps: reps,
        weight: weight,
        distance: distance,
        durationMinutes: durationMinutes,
      );

      _logs.insert(
        0,
        ExerciseLog(
          id: newId,
          libraryExerciseId: exercise.id,
          exerciseName: exercise.name,
          category: exercise.category,
          primaryMuscles: exercise.primaryMuscles,
          loggedAt: effectiveDate,
          sets: sets,
          reps: reps,
          weight: weight,
          distance: distance,
          durationMinutes: durationMinutes,
        ),
      );

      // Re-sort in case the user backdated loggedAt earlier than the newest log
      _logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

      _view?.displayRecentLogs(_logs);
      _view?.onLogSaved();
    } catch (e) {
      debugPrint('Failed to save exercise log: $e');
      _view?.showError('Failed to save exercise log.');
    } finally {
      _view?.hideLoading();
    }
  }

  Future<void> deleteExerciseLog(String logId) async {
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final removedLog = _logs.removeAt(index);
    _view?.displayRecentLogs(_logs);

    try {
      await _exerciseLogRepository.deleteExerciseLog(logId);
    } catch (e) {
      _logs.insert(index, removedLog);
      _view?.displayRecentLogs(_logs);
      _view?.showError('Failed to delete exercise log.');
    }
  }

  LibraryExercise? selectGoalSuggestion(MetricGoal goal) {
    for (final exercise in _exercises) {
      if (exercise.id == goal.libraryExerciseId) {
        return exercise;
      }
    }
    return null;
  }

  void detachView() {
    _view = null;
  }
}
