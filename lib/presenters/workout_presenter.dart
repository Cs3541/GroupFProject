import '../models/workout_model.dart';

class WorkoutPresenter {
  

  final List<Workout> _workouts = [];

  List<Workout> get workouts => _workouts;

  Future<void> loadAssignments() async {
    final fetched = await Workout.fetchWorkout();

    _workouts
      ..clear()
      ..addAll(fetched);
  }

  Future<void> addWorkout(String workoutType, int duration) async {
    final id = await Workout.addWorkout(workoutType, duration);
    if (id == null) return;

    _workouts.add(Workout(
      id: id,
      workoutType: workoutType,
      duration: duration,

      ));
  }

  Future<void> toggleCompleted(int index) async {
    await Workout.updateCompletionStatus(index, _workouts);
    _workouts[index].isCompleted = !_workouts[index].isCompleted;
  }

  Future<void> deleteWorkout(int index) async {
    final workout = _workouts[index];
    if (workout.id == null) return;

    await Workout.deleteWorkout(workout.id!);
    _workouts.remove(workout);
  }

  int get totalWorkouts => _workouts.length;

  int get completedWorkouts => _workouts.where((a) => a.isCompleted).length;
}