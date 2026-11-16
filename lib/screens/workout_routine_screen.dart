import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../presenters/workout_presenter.dart';
// only the library search widget; both files have a WorkoutRoutineScreen class
import '../views/workout_routine_view.dart' show ExerciseLibrarySearch, ExerciseDetailScreen;


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
    
    //should swap load assignments to load workout routines. 
    await presenter.loadWorkoutRoutines();
    setState(() => _isLoading = false);
  }
//added to open the library data stuff for the exercises details like how the serach bar does. (within workout)
  Future<void> _OpenExerciseDetails(Exercise exercise) async {
    if (exercise.libraryExerciseId == null) return;

    final libraryExercise = await LibraryExercise.fetchLibrary();

    for (var item in libraryExercise) {
      if (item.id == exercise.libraryExerciseId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: item),
          ),
        );
        return;
      }
    }

  }


  void _showAddWorkoutDialog() {
    String workoutType = '';
    String durationText = '';
    String search = '';
    String? workoutGroup = 'other';

    Map<String, Exercise> selectedExercises = {};

    final LibraryFuture = LibraryExercise.fetchLibrary(); 
    

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
                  setState(() {
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

              FutureBuilder<List<LibraryExercise>>(
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
                          value: selectedExercises.containsKey(exercise.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedExercises[exercise.id] = Exercise(
                                  name: exercise.name,
                                  libraryExerciseId: exercise.id,
                                );
                              } else {
                                selectedExercises.remove(exercise.id);
                              }
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
              ...selectedExercises.values.map((exercise) {
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
                        setState(() {
                          exercise.sets = value;
                          exercise.completedSets = List.filled(value, false);
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Weight (Optional)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
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
                    exercises: selectedExercises.values.toList(),
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
                                onTap: () => _OpenExerciseDetails(exercise),
                              ),
                              ...List.generate(exercise.sets, (setIndex) {
                                return CheckboxListTile(
                                  title: Text('Set ${setIndex + 1}'),
                                  value: exercise.completedSets[setIndex],
                                  onChanged: (value) async {
                                    await presenter.updateExerciseStatus(workout.id!, exerciseIndex, setIndex,);
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                );
                              }),
                            ],
                          );
                        }),
                      ],
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

