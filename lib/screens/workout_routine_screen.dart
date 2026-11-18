import 'package:flutter/material.dart';
import '../presenters/workout_presenter.dart';
// only the library search widget; both files have a WorkoutRoutineScreen class
import '../views/workout_routine_view.dart' show ExerciseLibrarySearch, ExerciseDetailScreen;
import '../models/workout_model.dart';


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
  _loadWorkoutRoutines();
}

  Future<void> _loadWorkoutRoutines() async {
    await presenter.loadWorkoutRoutines();
    setState(() => _isLoading = false);
  }
//added to open the library data stuff for the exercises details like how the serach bar does. (within workout)
  Future<void> _OpenExerciseDetails(String? exerciseId) async {
    if (exerciseId == null) return;

    final exercise = await presenter.getLibraryExerciseById(exerciseId);

    if (exercise != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(
            exercise: exercise,
          ),
        ), 
      );

      }
    }

  void _showEditExerciseDialog(
    String workoutId,
    int exerciseIndex,
    String exerciseName,
    int sets,
    int? weight,
  ) {
    int updatedSets = sets;
    int? updatedWeight = weight;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $exerciseName'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: updatedSets,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  items: List.generate(10, (index) {
                    final value = index + 1;
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value sets'),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      updatedSets = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: updatedWeight?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (Optional)'),
                  onChanged: (value) {
                    updatedWeight = int.tryParse(value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final workout = presenter.workouts.firstWhere(
                  (item) => item.id == workoutId,
                  orElse: () => throw StateError('Workout not found'),
                );

                if (exerciseIndex >= 0 && exerciseIndex < workout.exercises.length) {
                  final exercise = workout.exercises[exerciseIndex];
                  exercise.resetSets(updatedSets); // Reset completedSets when sets change
                  exercise.weight = updatedWeight;
                }

                if (!mounted) return;
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddWorkoutDialog() {
    String workoutType = '';
    String durationText = '';
    String search = '';
    String? workoutGroup = 'other';

    final LibraryFuture = presenter.loadLibraryExercises(); 
    

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          title: const Text('Add Workout Routine'),
          content: SizedBox(
            width: 350,
            height: 450,
            child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Workout Routine Name'),
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
              const Divider(),
              const Text('Select Exercises',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Exercises',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    search = value;
                  });
                },
              ),

              FutureBuilder(
                future: LibraryFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final exercises = snapshot.data!.where((exercise) {
                    return exercise.name.toLowerCase().contains(search.toLowerCase());
                  }).toList();

                  return SizedBox(
                    height: 150,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: exercises.length,
                      itemBuilder: (context, index){
                        final exercise = exercises[index];

                        return CheckboxListTile(
                          title: Text(exercise.name),
                          value: presenter.getSelectedExercises().any(
                            (e) => e.libraryExerciseId == exercise.id,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                                presenter.toggleExerciseSelection(exercise.id, exercise.name, value== true);
                               
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),

              const Divider(),

              const Text('Selected Exercises'),
              ...presenter.getSelectedExercises().map((exercise) {
                return Column(
                  children: [
                    Text(exercise.name),
                    DropdownButton<int>(
                      value: exercise.sets,
                      items: List.generate(10, (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1} sets'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          exercise.sets = value;
                          exercise.resetSets(value); // Reset completedSets when sets change
                          exercise.completedSets = List.filled(value, false);
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Weight (Optional)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          exercise.weight = int.tryParse(value);
                        });
                      },
                    ),
                  ],
                );
              }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (workoutType.trim().isNotEmpty) {
                  await presenter.addWorkout(
                    workoutType.trim(),
                    int.tryParse(durationText) ?? 0,
                    workoutGroup: workoutGroup,
                    exercises: presenter.getSelectedExercises().toList(),
                  );

                  if (!mounted) return;
                  setState(() {});
                  Navigator.pop(context);
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
  List<Widget> _buildRoutineContents(workout) {
    return [
    const Padding( //Moved the active routine dialog into a widget to allow for canceling out.
      padding: EdgeInsets.all(8.0),
      child: Text('Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
    if (workout.exercises.isEmpty)
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No exercises added yet.'),
      ),
    ...workout.exercises.asMap().entries.map((entry) {
      final exerciseIndex = entry.key;
      final exercise = entry.value;

      return Column(
        children: [
          ListTile(
            title: Text(exercise.name),
            subtitle: Text('Sets: ${exercise.sets}, Weight: ${exercise.weight ?? 'N/A'}'),
            onTap: () => _OpenExerciseDetails(exercise.libraryExerciseId),
            // Changed this button so that it adds a set if the routine is active, and functions as it did before if the routine is not active.
            trailing: presenter.isRoutineActive(workout.id!)
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add set',
                    onPressed: () => setState(() =>
                        presenter.addSet(workout.id!, exerciseIndex)),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit exercise',
                    onPressed: () {
                      _showEditExerciseDialog(workout.id!, exerciseIndex, exercise.name, exercise.sets, exercise.weight);

                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
          ),
          ...List.generate(exercise.sets, (setIndex) {
            final isActive = presenter.isRoutineActive(workout.id!);
            return CheckboxListTile(
              // Display the set number and input fields for reps and weight
              title: Row(
                children: [
                  Text('Set ${setIndex + 1}'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50, //ran into overflow error with new button so had to shrink
                    child: TextFormField(
                      // key includes isActive so the boxes reset to empty after Finish
                      key: ValueKey('reps-${workout.id}-$exerciseIndex-$setIndex-$isActive-${exercise.sets}'),
                      initialValue: exercise.setReps[setIndex]?.toString() ?? '',
                      enabled: isActive,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                      onChanged: (value) { 
                        presenter.updateSetReps(
                          workout.id!, exerciseIndex, setIndex, int.tryParse(value));
                          setState(() {}); 
                      }
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 75, //ran into overflow error with new button so had to shrink
                    child: TextFormField(
                      key: ValueKey('weight-${workout.id}-$exerciseIndex-$setIndex-$isActive-${exercise.sets}'),
                      initialValue: exercise.setWeights[setIndex]?.toString() ?? '',
                      enabled: isActive,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        hintText: exercise.weight?.toString(),
                        suffixText: presenter.weightUnit,
                        isDense: true,
                      ),
                        //Refactored so that typing causes a screen redraw, 
                        //enabling the finish workout button if typing is the last step to completing a routine.
                        //Typing previously did not casue a screen redraw, so the finish button would not enable until a checkbox was clicked.
                        onChanged: (value) {
                          presenter.updateSetWeight(
                            workout.id!, exerciseIndex, setIndex, double.tryParse(value));
                        setState(() {});
                      },

                    ),
                  ),
                ],
              ),

              value: exercise.completedSets[setIndex],
                //adding button to remove sets from an ACTIVE routine.
                secondary: isActive
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remove set',
                      onPressed: () => setState(() =>
                          presenter.removeSet(workout.id!, exerciseIndex, setIndex)),
                    )
                  : null,
              //changing onChanged here so that you can only mark off sets when a routine is active.
              onChanged: presenter.isRoutineActive(workout.id!) 
              ? (value) async {
                await presenter.updateExerciseStatus(workout.id!, exerciseIndex, setIndex,);
                if (!mounted) return;
                setState(() {});
              }
              : null,
            );
          }),
        ],
      );
    }),
    //Adding start/finish button for routine activation toggle
    if (workout.exercises.isNotEmpty)
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: presenter.isRoutineActive(workout.id!) 
              //Rewrote the button function to be disabled if the routine is not complete.
              ? Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Finish Routine'),
                    // null disables the button
                    onPressed: !presenter.isRoutineReady(workout.id!)
                        ? null
                        : () async {
                            final saved = await presenter.finishRoutine();
                            if (!context.mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(saved
                                    ? 'Workout Saved!'
                                    : 'Could not save workout.')),
                            );
                          },
                  ),
                  if (!presenter.isRoutineReady(workout.id!))
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${presenter.incompleteSetCount(workout.id!)} set(s) still need reps, '
                        'weight and a check, or remove them.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              )
          : ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Routine'),
            onPressed: () => setState(() => presenter.startRoutine(workout.id!)),
            ),
      ),  
    ];
  }
    //Cancel routine dialog
    Future<void> _confirmCancelRoutine() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel routine?'),
        content: const Text('Your logged sets will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard != true) return;

    await presenter.cancelRoutine();
    if (!mounted) return;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    //While a routine is active, it now covers the full routines screen but leaves the main nav bar open.
    //Added cancel button to exit out of an active routine without saving.
    final activeRoutine = presenter.activeRoutine;
    if (activeRoutine != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(activeRoutine.workoutType),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel routine',
              onPressed: _confirmCancelRoutine,
            ),
          ],
        ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: _buildRoutineContents(activeRoutine),
      ),
    );
    }
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
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
          ),
        ),

          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWorkoutDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          const ExerciseLibrarySearch(),
          Expanded(
            child:
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
                      style:  TextStyle(fontWeight: FontWeight.bold,
                      //should cross out the completed workout once the checkboxes are marked. some trouble with it not working yet.
                      decoration: workout.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    ),
                    subtitle: Text(workout.duration.toString()),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.favorite, color: presenter.hasLiked(workout.id!) ? Colors.pinkAccent : Colors.grey),
                            onPressed: presenter.hasLiked(workout.id!)
                                ? null
                                : () async {
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
                      children: _buildRoutineContents(workout),
                  ),
                );
              },
          ),
          ),
        ],
      ),
    );
  }
}

