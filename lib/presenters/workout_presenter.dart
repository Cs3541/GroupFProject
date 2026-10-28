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

    _workouts.add(
      Workout(id: id, workoutType: workoutType, duration: duration),
    );
  }

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

  Future<void> deleteWorkout(int index) async {
    final workout = _workouts[index];
    if (workout.id == null) return;

    await Workout.deleteWorkout(workout.id!);
    _workouts.remove(workout);
  }

  int get totalWorkouts => _workouts.length;

  int get completedWorkouts => _workouts.where((a) => a.isCompleted).length;
}
