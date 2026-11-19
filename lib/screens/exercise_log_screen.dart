import 'package:fallguys_fitness_app/presenters/exercise_log_presenter.dart';
import 'package:fallguys_fitness_app/views/exercise_log_view.dart';
import 'package:flutter/material.dart';

import '../models/exercise_log_model.dart';
import '../models/goal_model.dart';
import '../models/workout_model.dart';

class ExerciseLogScreen extends StatefulWidget {
  const ExerciseLogScreen({super.key});

  @override
  State<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends State<ExerciseLogScreen>
    implements ExerciseLogView {
  late ExerciseLogPresenter _presenter;

  bool _isLoading = true;
  List<LibraryExercise> _exerciseLibrary = [];
  List<MetricGoal> _metricGoals = [];
  List<ExerciseLog> _exerciseLogs = [];

  @override
  void initState() {
    super.initState();
    // Inject view and repositories into the presenter.
    final repository = FirestoreExerciseLogRepository();
    _presenter = ExerciseLogPresenter(
      this,
      repository,
      FirestoreGoalsRepository(repository),
    );
    _presenter.loadExercises();
  }

  @override
  void showLoading() {
    if (!mounted) return;
    setState(() => _isLoading = true);
  }

  @override
  void hideLoading() {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void displayExerciseLibrary(List<LibraryExercise> exercises) {
    if (!mounted) return;
    setState(() => _exerciseLibrary = exercises);
  }

  @override
  void displayRecentLogs(List<ExerciseLog> logs) {
    if (!mounted) return;
    setState(() => _exerciseLogs = logs);
  }

  @override
  void displayGoalSuggestions(List<MetricGoal> goals) {
    if (!mounted) return;
    setState(() => _metricGoals = goals);
  }

  @override
  void onLogSaved() {
    if (!mounted) return;
    setState(() {});
    //force ui refresh
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _presenter.detachView();
    super.dispose();
  }

  void _showLogExerciseDialog() {
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final distanceController = TextEditingController();
    final durationController = TextEditingController();

    LibraryExercise? selectedExercise;
    TextEditingController? autocompleteController;

    // Deduplicate goal suggestions by libraryExerciseId
    final uniqueGoalExercises = <String, MetricGoal>{};
    for (final goal in _metricGoals) {
      uniqueGoalExercises.putIfAbsent(goal.libraryExerciseId, () => goal);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isCardio =
                selectedExercise?.category?.toLowerCase() == 'cardio';

            return AlertDialog(
              title: const Text('Log Exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Goal Suggestions Bar
                    if (uniqueGoalExercises.isNotEmpty) ...[
                      const Text(
                        'Suggested from Goals:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: uniqueGoalExercises.values.map((goal) {
                          return ActionChip(
                            label: Text(goal.title),
                            onPressed: () {
                              final match = _presenter.selectGoalSuggestion(
                                goal,
                              );
                              if (match != null) {
                                setDialogState(() {
                                  selectedExercise = match;
                                  autocompleteController?.text = match.name;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Exercise Search Autocomplete
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
                        setDialogState(() {
                          selectedExercise = selection;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                            autocompleteController = controller;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (_) {
                                if (selectedExercise != null) {
                                  setDialogState(() => selectedExercise = null);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Search Exercise',
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 16),

                    // 3. Conditional Inputs (Cardio vs. Strength)
                    if (isCardio) ...[
                      TextField(
                        controller: distanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Distance (miles)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: durationController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: setsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sets'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reps'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (lbs)',
                        ),
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
                    if (selectedExercise == null) return;

                    final exercise = selectedExercise!;
                    final sets = int.tryParse(setsController.text.trim());
                    final reps = int.tryParse(repsController.text.trim());
                    final weight = double.tryParse(
                      weightController.text.trim(),
                    );
                    final distance = double.tryParse(
                      distanceController.text.trim(),
                    );
                    final duration = double.tryParse(
                      durationController.text.trim(),
                    );

                    // Unfocus keyboard/overlay and close dialog BEFORE triggering presenter rebuilds
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);

                    _presenter.addExerciseLog(
                      exercise: exercise,
                      sets: sets,
                      reps: reps,
                      weight: weight,
                      distance: distance,
                      durationMinutes: duration,
                    );
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

  String _formatLogSummary(ExerciseLog log) {
    final parts = <String>[];
    if (log.sets != null && log.reps != null) {
      parts.add('${log.sets} sets × ${log.reps} reps');
    } else if (log.sets != null) {
      parts.add('${log.sets} sets');
    } else if (log.reps != null) {
      parts.add('${log.reps} reps');
    }
    if (log.weight != null) parts.add('${log.weight} lbs');
    if (log.distance != null) parts.add('${log.distance} mi');
    if (log.durationMinutes != null) parts.add('${log.durationMinutes} min');

    final date =
        '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year}';
    return parts.isEmpty ? date : '${parts.join(' • ')}  ($date)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogExerciseDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exerciseLogs.isEmpty
          ? const Center(
              child: Text('No exercises logged yet. Tap + to start.'),
            )
          : RefreshIndicator(
              onRefresh: () => _presenter.loadExercises(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _exerciseLogs.length,
                itemBuilder: (context, index) {
                  final log = _exerciseLogs[index];
                  return Dismissible(
                    key: Key(log.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _presenter.deleteExerciseLog(log.id),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          log.exerciseName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_formatLogSummary(log)),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}