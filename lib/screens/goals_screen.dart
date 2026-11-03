import 'package:flutter/material.dart';

import '../presenters/goals_presenter.dart';
import '../views/goals_view.dart';
import '../repositories/goals_repository.dart';
import '../repositories/mock_goals_repository.dart';
import '../models/goal_model.dart';

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
    _presenter = GoalsPresenter(this, MockGoalsRepository());
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
      appBar: AppBar(title: const Text('My Goals'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _presenter.loadGoals(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Distance Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Build Metric Goal Cards with Progress Bars
                  ..._metricGoals.map((goal) {
                    final progress = (goal.currentMiles / goal.targetMiles)
                        .clamp(0.0, 1.0);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${goal.currentMiles} / ${goal.targetMiles} mi',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Weekly Achievements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Build Habit Goals Checklist in a single unified Card
                  Card(
                    elevation: 2,
                    child: Column(
                      children: _habitGoals
                          .map(
                            (goal) => CheckboxListTile(
                              title: Text(
                                goal.title,
                                style: TextStyle(
                                  decoration: goal.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: goal.isCompleted
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              value: goal.isCompleted,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool? value) {
                                if (value != null) {
                                  _presenter.toggleHabitGoal(goal.id, value);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
