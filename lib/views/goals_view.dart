import 'package:fallguys_fitness_app/models/workout_model.dart';

import '../models/goal_model.dart';


// ###################################
// ----- Abstract View Contract ------
// ###################################
abstract class GoalsView {
  void showLoading();
  void hideLoading();

  // for quantifiable goals like "run x number of miles per week"
  void displayMetricGoals(List<MetricGoal> goals);

  // for required "goal achievement section for things they did"
  void displayAchievementGoals(List<HabitGoal> achievements);

  void onGoalUpdated(String goalId);
  void showError(String message);

  void displayExerciseLibrary(List<LibraryExercise> exercies);
}
