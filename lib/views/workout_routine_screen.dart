import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_model.dart';
import '../presenters/workout_presenter.dart';


class WorkoutRoutineScreen extends StatefulWidget {
  const WorkoutRoutineScreen({super.key});

  @override
  State<WorkoutRoutineScreen> createState() => _WorkoutRoutineScreenState();
}

class _WorkoutRoutineScreenState extends State<WorkoutRoutineScreen> {
  final WorkoutPresenter presenter = WorkoutPresenter();
  bool _isLoading = true;

  String? _selectedWorkoutFilter;
  String _search = '';
// can add more workout types later. 
  final List<String> _workoutGroups = [
    'chest',
    'back',
    'legs',
    'arms',
    'core',
    'full body',  
    'cardio',
    'other', 
  ];



@override
void initState() {
  super.initState();
  // the presenter calls these while a timer is running
  presenter.onTimerTick = () {
    if (mounted) setState(() {});
  };
  presenter.onExerciseFinished = _handleExerciseFinished;
  _loadWorkoutRoutines();
}

@override
void dispose() {
  // clear the callbacks first so stopTimer doesn't call setState on a disposed screen
  presenter.onTimerTick = null;
  presenter.onExerciseFinished = null;
  presenter.stopTimer();
  super.dispose();
}

  Future<void> _loadWorkoutRoutines() async {
    
    //should swap load assignments to load workout routines. 
    await presenter.loadWorkoutRoutines();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _handleExerciseFinished(Exercise finished, Exercise? next) {
    if (!mounted) return;
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);

    final message = next == null
        ? "Time's up for ${finished.name}! Workout timers complete."
        : "Time's up for ${finished.name}! Next: ${next.name}";
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddWorkoutDialog() {
    String workoutType = '';
    //check these again later
    String durationText = '';
    String exerciseNamesText = '';
    String? workoutGroup = 'other';

    showDialog(
      context: context,
      builder: (dialogContext) {
        // StatefulBuilder gives the dialog its own setState so the dropdown updates
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Workout Routine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Workout Routine Type'),
                    onChanged: (value) => workoutType = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Duration (Optional)'),
                    onChanged: (value) => durationText = value,
                  ),
                  DropdownButton<String>(
                    value: workoutGroup,
                    onChanged: (value) {
                      setDialogState(() {
                        workoutGroup = value;
                      });
                    },
                    items: _workoutGroups.map((group) {
                      return DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Exercises (Optional)',
                      hintText: 'Pushups:60, Squats:45, Plank',
                      helperText: 'Separate with commas. Add :seconds for a timer.',
                      helperMaxLines: 2,
                    ),
                    onChanged: (value) => exerciseNamesText = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (workoutType.trim().isNotEmpty) {
                      await presenter.addWorkout(
                        workoutType.trim(),
                        int.tryParse(durationText) ?? 0,
                        workoutGroup: workoutGroup,
                        exerciseNames: exerciseNamesText.split(',').map((e) => e.trim()).toList(),
                      );
                      if (mounted) setState(() {});
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Shows "Start workout" or, while this workout's timer is running, the countdown + controls.
  Widget _buildTimerPanel(Workout workout) {
    if (!presenter.hasTimedExercises(workout)) return const SizedBox.shrink();

    final isActive = presenter.activeWorkoutId == workout.id;
    if (!isActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.timer),
            label: const Text('Start workout'),
            onPressed: () {
              final started = presenter.startWorkout(workout.id!);
              if (!started) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All timed exercises are already completed.')),
                );
              }
            },
          ),
        ),
      );
    }

    final exercise = presenter.activeExercise;
    final isPaused = presenter.isTimerPaused;

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            exercise?.name ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            WorkoutPresenter.formatSeconds(presenter.remainingSeconds),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: presenter.remainingFraction),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: isPaused ? 'Resume' : 'Pause',
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: isPaused ? presenter.resumeTimer : presenter.pauseTimer,
              ),
              TextButton(
                onPressed: () => presenter.addTime(15),
                child: const Text('+15s'),
              ),
              IconButton(
                tooltip: 'Skip',
                icon: const Icon(Icons.skip_next),
                onPressed: presenter.skipExercise,
              ),
              IconButton(
                tooltip: 'Stop',
                icon: const Icon(Icons.stop),
                onPressed: presenter.stopTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workouts = presenter.workouts;
    final displayedWorkouts = workouts.where((workout) {
      final matchesGroup = _selectedWorkoutFilter == null ||
      workout.workoutGroup == _selectedWorkoutFilter;
      final matchesSearch = workout.workoutType.toLowerCase().contains(_search.toLowerCase());

      return matchesGroup && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Routines'),
        actions: [
          DropdownButton<String>(
            value: _selectedWorkoutFilter,
            onChanged: (value) {
              setState(() {
                _selectedWorkoutFilter = value;
              });
            },
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All'),
              ),
              ..._workoutGroups.map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWorkoutDialog(),
          ),
        ],
      ),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: displayedWorkouts.length,
              itemBuilder: (context, index) {
                final workout = displayedWorkouts[index];
                
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text(
                      workout.workoutType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(workout.duration.toString()),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                            onPressed: () async {
                              await presenter.updateLikes(workout.id!);
                              if (!mounted) return;
                              setState(() {});
                            },
                          ),

                          Text(workout.likes.toString()),
                          IconButton(icon:const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await presenter.deleteWorkout(workout.id!);
                              if (!mounted) return;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        _buildTimerPanel(workout),
                        if (workout.exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No exercises added yet.'),
                          ),
                        ...workout.exercises.asMap().entries.map((entry) {
                          final exerciseIndex = entry.key;
                          final exercise = entry.value;
                          final duration = exercise.durationSeconds;
                          final isActive = presenter.isExerciseActive(workout.id, exerciseIndex);

                          return CheckboxListTile(
                            title: Text(exercise.name),
                            subtitle: duration == null
                                ? null
                                : Text(isActive
                                    ? '${WorkoutPresenter.formatSeconds(presenter.remainingSeconds)} left'
                                    : WorkoutPresenter.formatSeconds(duration)),
                            selected: isActive,
                            value: exercise.isCompleted,
                            onChanged: (value) async {
                              await presenter.updateExerciseCompleted(workout.id!, exerciseIndex,);
                              if (!mounted) return;
                              setState(() {});
                            },
                            // play button for exercises that have a timer
                            secondary: duration == null
                                ? null
                                : IconButton(
                                    tooltip: isActive ? (presenter.isTimerPaused ? 'Resume' : 'Pause') : 'Start timer',
                                    icon: Icon(
                                      isActive
                                          ? (presenter.isTimerPaused ? Icons.play_arrow : Icons.pause)
                                          : Icons.play_circle_outline,
                                    ),
                                    onPressed: () {
                                      if (!isActive) {
                                        presenter.startExerciseTimer(workout.id!, exerciseIndex);
                                      } else if (presenter.isTimerPaused) {
                                        presenter.resumeTimer();
                                      } else {
                                        presenter.pauseTimer();
                                      }
                                    },
                                  ),
                          );
                        }),
                      ],
                  ),
                );
              },
          ),
        );
  }
}

