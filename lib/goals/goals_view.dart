import '';

// view contract
abstract class GoalsView {
  void showLoading();
  void hideLoading();

  // for quantifiable goals like "run x number of miles per week"
  void displayMetricGoals(List<MetricGoal> goals);

  // for required "goal achievement section for things they did"
  void displayAchivementGoals(List<HabitGoal> achievements);

  void onGoalUpdated(String goalId);
  void showError(String message);
}

