import '../models/exercise_log_model.dart';
import '../models/goal_model.dart';
import '../models/workout_model.dart';

abstract class ExerciseLogView {
  void displayExerciseLibrary(List<LibraryExercise> exercises);
  void displayRecentLogs(List<ExerciseLog> logs);
  void displayGoalSuggestions(List<MetricGoal> goals);
  void showLoading();
  void hideLoading();
  void showError(String message);
  void onLogSaved();
}