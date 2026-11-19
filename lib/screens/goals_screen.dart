import 'package:flutter/material.dart';

import '../models/exercise_log_model.dart';
import '../presenters/goals_presenter.dart';
import '../models/goal_model.dart';
import '../views/goals_view.dart';
import '../models/workout_model.dart';

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
  List<LibraryExercise> _exerciseLibrary = [];

  @override
  void initState() {
    super.initState();
    // Inject view and repository into the presenter.
    _presenter = GoalsPresenter(
      this,
      FirestoreGoalsRepository(FirestoreExerciseLogRepository()),
      FirestoreExerciseLogRepository(),
    );
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
  void displayExerciseLibrary(List<LibraryExercise> exercises) {
    setState(() => _exerciseLibrary = exercises);
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

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController();
    bool isMetric = true;
    LibraryExercise? selectedExercise;
    String selectedFrequency = 'daily';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set New Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Metric')),
                        ButtonSegment(value: false, label: Text('Habit')),
                      ],
                      selected: {isMetric},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setDialogState(() => isMetric = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isMetric) ...[
                      Autocomplete<LibraryExercise>(
                        displayStringForOption: (option) => option.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.trim().isEmpty) {
                            return const Iterable<LibraryExercise>.empty();
                          }
                          return _exerciseLibrary.where(
                            (ex) => ex.matches(textEditingValue.text),
                          );
                        },
                        onSelected: (LibraryExercise selection) {
                          selectedExercise = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              controller,
                              focusNode,
                              onEditingComplete,
                            ) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                onChanged: (_) => selectedExercise = null,
                                decoration: const InputDecoration(
                                  labelText: 'Search Exercise',
                                ),
                              );
                            },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target Value',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (e.g. lbs, reps, miles)',
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Habit Title (e.g. Stretch 10 mins)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'daily', label: Text('Daily')),
                          ButtonSegment(value: 'weekly', label: Text('Weekly')),
                        ],
                        selected: {selectedFrequency},
                        onSelectionChanged: (Set<String> newSelection) {
                          setDialogState(
                            () => selectedFrequency = newSelection.first,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isMetric) {
                      if (selectedExercise == null) return;
                      final target =
                          double.tryParse(targetController.text.trim()) ?? 0.0;
                      if (target <= 0) return;
                      final unit = unitController.text.trim();
                      if (unit.isEmpty) return;

                      _presenter.addMetricGoal(
                        selectedExercise!.id,
                        selectedExercise!.name,
                        target,
                        unit,
                      );
                    } else {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      _presenter.addHabitGoal(title, selectedFrequency);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Goals'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
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
                      'Metric Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Build Metric Goal Cards with Progress Bars
                  ..._metricGoals.map((goal) {
                    final progress = (goal.currentValue / goal.targetValue)
                        .clamp(0.0, 1.0);
                    return Dismissible(
                      key: Key('metric_${goal.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Delete Goal"),
                              content: const Text(
                                "Are you sure you want to delete this goal?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) =>
                          _presenter.deleteGoal(goal.id, isMetric: true),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: progress),
                            ],
                          ),
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
                            (goal) => Dismissible(
                              key: Key('habit_${goal.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Delete Goal"),
                                      content: const Text(
                                        "Are you sure you want to delete this achievement?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) => _presenter.deleteGoal(
                                goal.id,
                                isMetric: false,
                              ),
                              child: CheckboxListTile(
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
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    _presenter.toggleHabitGoal(goal.id, value);
                                  }
                                },
                              ),
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
