import 'package:flutter/material.dart';
import '../presenters/workout_presenter.dart';
// only the library search widget; both files have a WorkoutRoutineScreen class
import '../views/workout_routine_screen.dart' show ExerciseLibrarySearch;


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

  void _showAddWorkoutDialog() {
    String workoutType = '';
    //check these again later
    String durationText = '';
    String exerciseNamesText = '';
    String? workoutGroup = 'other';

    showDialog(
      context: context,
      builder: (context) {
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
              TextField(
                decoration: const InputDecoration(labelText: 'Exercise Names (Optional)'),
                onChanged: (value) => exerciseNamesText = value,
              ),
            ],
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
                    exerciseNames: exerciseNamesText.split(',').map((e) => e.trim()).toList(),
                  );
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
                        if (workout.exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No exercises added yet.'),
                          ),
                        ...workout.exercises.asMap().entries.map((entry) {
                          final exerciseIndex = entry.key;
                          final exercise = entry.value;
                          return CheckboxListTile(
                            title: Text(exercise.name),
                            value: exercise.isCompleted,
                            onChanged: (value) async {
                              await presenter.updateExerciseCompleted(workout.id!, exerciseIndex,);
                              if (!mounted) return;
                              setState(() {});
                            },
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

