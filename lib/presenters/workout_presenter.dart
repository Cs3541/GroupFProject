import '../models/workout_model.dart';

class WorkoutPresenter {
  final List<Workout> _workouts = [];

  List<Workout> get workouts => _workouts;
  
  Future<void> loadWorkoutRoutines() async {
    final fetched = await Workout.fetchWorkout();
    final samples = await Workout.fetchSampleWorkouts();

    _workouts
      ..clear()
      ..addAll(fetched)
      ..addAll(samples);
  }
// edited this section to include workout groups and exercises
  Future<void> addWorkout(String workoutType, int duration, {String? workoutGroup, List<String> exerciseNames = const []}) async {
    final id = await Workout.addWorkout(workoutType, duration, workoutGroup: workoutGroup, exerciseNames: exerciseNames);
    if (id == null) return;

    final newExercises = exerciseNames
        .where((name) => name.isNotEmpty)
        .map((name) => Exercise(name: name.trim()))
        .toList();

    _workouts.add(
      Workout(id: id, workoutType: workoutType, duration: duration, workoutGroup: workoutGroup, exercises: newExercises),
    );
  }
// end section
  Future<void> toggleCompleted(String id) async {
    // Finding the local workout by its firestore ID
    final index = _workouts.indexWhere((workout) => workout.id == id);

    //guard in case the ID isn't found in the local list
    if (index == -1) return;

    final currentStatus = _workouts[index].isCompleted;

    //simple call to backend 
    await Workout.updateCompletionStatus(id, currentStatus);

    // Update local state to match the backend
    _workouts[index].isCompleted = !currentStatus;
  }
//new section for updating exercise completion status
  Future<void> updateExerciseCompleted(String workoutId, int exerciseIndex,) async {

    final workoutIndex = _workouts.indexWhere((workout) => workout.id == workoutId);
    if (workoutIndex == -1) return;

    final workout = _workouts[workoutIndex];
    if (exerciseIndex < 0 || exerciseIndex >= workout.exercises.length) return;

    final exercise = workout.exercises[exerciseIndex];
    exercise.isCompleted = !exercise.isCompleted;
    
    await Workout.updateExerciseStatus(workoutId, workout.exercises);

  }
// end section for updating exercise completion status

// section for the likes system
Future<void> updateLikes(String workoutId) async {
    final workoutIndex = _workouts.indexWhere((workout) => workout.id == workoutId);
    if (workoutIndex == -1) return;

    final newLikes = _workouts[workoutIndex].likes + 1;

    await Workout.updateLikes(workoutId, newLikes);
    _workouts[workoutIndex].likes = newLikes;
  }

  Future<void> deleteWorkout(String id) async {

    await Workout.deleteWorkout(id);
    _workouts.removeWhere((workout) => workout.id == id);
  }

  int get totalWorkouts => _workouts.length;

  int get completedWorkouts => _workouts.where((a) => a.isCompleted).length;
}
