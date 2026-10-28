import 'package:flutter/material.dart';

import 'goals_presenter.dart';
import 'goals_view.dart';
import 'goals_repository.dart';
import '../core/models/goal_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

// The State class implements the GoalsView contract
class _GoalsScreenState extends State<GoalsScreen> implements GoalsView {
  late GoalsPresenter _presenter;

  bool _isLoading = true;
  List<MetricGoal> _metricGoals = [];
  List<HabitGoal> _habitGoals = [];

  @override
  void initState() {
    super.initState();
    // Inject view and repository into the presenter.
    _presenter = GoalsPresenter(this, GoalsRepository());
    _presenter.loadGoals();
  }

  // --- GoalsView Contract Implementation ---

  @override
  void showLoading() {
    setState(() => _isLoading = true);
  }

  @override
  void hideLoading() {
    setState(() => _isLoading = false);
  }

  @override
  void displayMetricGoals(List<MetricGoal> goals) {
    setState(() => _metricGoals = goals);
  }

  @override
  void displayAchievementGoals(List<HabitGoal> achievements) {
    setState(() => _habitGoals = achievements);
  }

  @override
  void onGoalUpdated(String goalId) {
    // Force a UI refresh if the presenter updates a specific goal's local state
    setState(() {});
  }

  @override
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Distance Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ..._metricGoals.map(
                  (goal) => ListTile(
                    title: Text(goal.title),
                    subtitle: Text(
                      '${goal.currentMiles} / ${goal.targetMiles} miles',
                    ),
                    trailing: goal.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.directions_run),
                  ),
                ),

                const Divider(height: 32),

                const Text(
                  'Weekly Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ..._habitGoals.map(
                  (goal) => CheckboxListTile(
                    title: Text(goal.title),
                    value: goal.isCompleted,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _presenter.toggleHabitGoal(goal.id, value);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
