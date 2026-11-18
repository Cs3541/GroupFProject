import 'dart:async';

import '../models/workout_model.dart';

class WorkoutPresenter {
  final List<Workout> _workouts = [];

  List<Workout> get workouts => _workouts;
  final Set<String> _likedWorkouts = {};
  List<LibraryExercise> _libraryExercises = [];
  final Map<String, Exercise> _selectedExercises = {};
  String? _activeRoutineId; //keeps track of which routine is active
  DateTime? _routineStartedAt; //timestamp start of routine
  String weightUnit = 'kg'; // fetches user's preferred weight unit; metric/kg by default

  bool isRoutineActive(String workoutId) => _activeRoutineId == workoutId;
  // ---------------- exercise timer state ----------------
  Timer? _timer;
  String? _activeWorkoutId;
  int? _activeExerciseIndex;
  DateTime? _endTime;
  Duration? _pausedRemaining;

  /// Called whenever the timer changes so the view can rebuild.
  void Function()? onTimerTick;

  /// Called when an exercise's time runs out. [next] is null when the workout is done.
  void Function(Exercise finished, Exercise? next)? onExerciseFinished;

  String? get activeWorkoutId => _activeWorkoutId;
  int? get activeExerciseIndex => _activeExerciseIndex;
  bool get isTimerPaused => _pausedRemaining != null;

  Exercise? get activeExercise {
    final workout = _findWorkout(_activeWorkoutId);
    final index = _activeExerciseIndex;
    if (workout == null || index == null || index >= workout.exercises.length) return null;
    return workout.exercises[index];
  }

  bool isExerciseActive(String? workoutId, int exerciseIndex) =>
      workoutId != null && workoutId == _activeWorkoutId && exerciseIndex == _activeExerciseIndex;

  /// Seconds left on the active exercise (rounded up so it shows 1 until it truly hits 0).
  int get remainingSeconds {
    final Duration remaining;
    if (_pausedRemaining != null) {
      remaining = _pausedRemaining!;
    } else if (_endTime != null) {
      remaining = _endTime!.difference(DateTime.now());
    } else {
      return 0;
    }
    if (remaining.isNegative) return 0;
    return (remaining.inMilliseconds / 1000).ceil();
  }

  /// Fraction of time left on the active exercise, 1.0 -> 0.0.
  double get remainingFraction {
    final total = activeExercise?.durationSeconds;
    if (total == null || total <= 0) return 0;
    return (remainingSeconds / total).clamp(0.0, 1.0);
  }

  /// Formats seconds as m:ss, e.g. 75 -> "1:15".
  static String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadWorkoutRoutines() async {
    final fetched = await Workout.fetchWorkout();
    weightUnit = await Workout.fetchWeightUnit(); 

    _workouts
      ..clear()
      ..addAll(fetched);

  }

  Future<List<LibraryExercise>> loadLibraryExercises() async {
    if (_libraryExercises.isEmpty) {
      _libraryExercises = await LibraryExercise.fetchLibrary();
    }
    return _libraryExercises;
  }

  Future<LibraryExercise?> getLibraryExerciseById(String id) async {
    final exercises = await loadLibraryExercises();

    for (final exercise in exercises) {
      if (exercise.id == id) {
        return exercise;
      }
    }

    return null;
  }

  List<Exercise> getSelectedExercises() {
    return _selectedExercises.values.toList();
  }

  void toggleExerciseSelection(String id, String name, bool selected) {
    if (selected) {
      _selectedExercises[id] = Exercise(name: name, libraryExerciseId: id);
    } else {
      _selectedExercises.remove(id);
    }
  }

  void updateSelectedExerciseSets(String id, int sets) {
    final exercise = _selectedExercises[id];

    if (exercise == null) return;
    exercise.resetSets(sets);
  }

  void updateSelectedExerciseWeight(String id, int? weight) {
    final exercise = _selectedExercises[id];

    if (exercise == null) return;
    exercise.weight = weight;
  }
// added to update the sets and weights as you go. increase and or decrease them
  Future<void> updateExerciseDetails(String workoutId, int exerciseIndex, int sets, int? weight) async {
    final workoutIndex = _workouts.indexWhere((workout) => workout.id == workoutId);
    if (workoutIndex == -1) return;

    final workout = _workouts[workoutIndex];
    if (exerciseIndex < 0 || exerciseIndex >= workout.exercises.length) return;

    final exercise = workout.exercises[exerciseIndex];

    exercise.resetSets(sets);
    exercise.weight = weight;

    await Workout.updateExerciseStatus(workoutId, workout.exercises);

  }
// edited this section to include workout groups and exercises
  Future<void> addWorkout(String workoutType, int duration, {String? workoutGroup, List<Exercise> exercises = const []}) async {
    String? id = await Workout.addWorkout(workoutType, duration, workoutGroup: workoutGroup, exercises: exercises);
    if (id == null) return;

    _workouts.add(
      Workout(id: id, workoutType: workoutType, duration: duration, workoutGroup: workoutGroup, exercises: exercises),
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

    if (_likedWorkouts.contains(workoutId)) return;
    

    final newLikes = _workouts[workoutIndex].likes + 1;

    await Workout.updateLikes(workoutId, newLikes);
    _workouts[workoutIndex].likes = newLikes;

    _likedWorkouts.add(workoutId);
  }

  bool hasLiked(String workoutId) { return _likedWorkouts.contains(workoutId); }

  Future<void> deleteWorkout(String id) async {
    if (id == _activeWorkoutId) stopTimer();

    await Workout.deleteWorkout(id);
    _workouts.removeWhere((workout) => workout.id == id);
  }

  int get totalWorkouts => _workouts.length;

  int get completedWorkouts => _workouts.where((a) => a.isCompleted).length;
// for individual exercise completion status(sets)
  Future<void> updateExerciseStatus(String workoutId, int exerciseIndex, int setIndex) async {
    int workoutIndex = _workouts.indexWhere((workout) => workout.id == workoutId);
    if (workoutIndex == -1) return;
    Workout workout = _workouts[workoutIndex];

    Exercise exercise = _workouts[workoutIndex].exercises[exerciseIndex];
      exercise.completedSets[setIndex] = !exercise.completedSets[setIndex];

      exercise.isCompleted = exercise.completedSets.isNotEmpty &&
          exercise.completedSets.every((set) => set);

          bool wasCompleted = _workouts[workoutIndex].isCompleted;

          workout.isCompleted = workout.exercises.isNotEmpty &&
          workout.exercises.every((exercise) => exercise.isCompleted);
    
    await Workout.updateExerciseStatus(workoutId, _workouts[workoutIndex].exercises);

    if (wasCompleted != workout.isCompleted) {
      await Workout.updateCompletionStatus(workoutId, !workout.isCompleted);
    }
  }
  //Routine start/finish
  void updateSetReps(String workoutId, int exerciseIndex, int setIndex, int? reps) {
    final exercise = _findWorkout(workoutId)?.exercises[exerciseIndex];
    if (exercise == null) return;
    exercise.setReps[setIndex] = reps;
  }

  void updateSetWeight(String workoutId, int exerciseIndex, int setIndex, double? weight) {
    final exercise = _findWorkout(workoutId)?.exercises[exerciseIndex];
    if (exercise == null) return;
    exercise.setWeights[setIndex] = weight;
  }

  void startRoutine(String workoutId) {
    _activeRoutineId = workoutId;
    _routineStartedAt = DateTime.now();
  }

  //Saves routine data to completed routines collection and resets active routine
  Future<bool> finishRoutine() async {
    final workout = _findWorkout(_activeRoutineId);
    final startedAt = _routineStartedAt;
    if (workout == null || startedAt == null) return false;

    final savedId = await Workout.saveCompletedWorkout(workout, startedAt, weightUnit);
    if (savedId == null) return false;

    for (final exercise in workout.exercises) {
      exercise.resetSets();
    }
    await Workout.updateExerciseStatus(workout.id!, workout.exercises);

    if (workout.isCompleted) {
      await Workout.updateCompletionStatus(workout.id!, true);
      workout.isCompleted = false;
    }
    _activeRoutineId = null;
    _routineStartedAt = null;
    return true;
  }

  // ---------------- exercise timer controls ----------------

  Workout? _findWorkout(String? id) {
    if (id == null) return null;
    final index = _workouts.indexWhere((workout) => workout.id == id);
    return index == -1 ? null : _workouts[index];
  }

  /// Index of the next unfinished exercise with a timer, starting at [from]. -1 if none.
  int _nextTimedIndex(Workout workout, int from) {
    for (var i = from; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      if (!exercise.isCompleted && (exercise.durationSeconds ?? 0) > 0) return i;
    }
    return -1;
  }

  bool hasTimedExercises(Workout workout) =>
      workout.exercises.any((exercise) => (exercise.durationSeconds ?? 0) > 0);

  /// Starts the first unfinished timed exercise. Returns false if there's nothing left to time.
  bool startWorkout(String workoutId) {
    final workout = _findWorkout(workoutId);
    if (workout == null) return false;
    final index = _nextTimedIndex(workout, 0);
    if (index == -1) return false;
    startExerciseTimer(workoutId, index);
    return true;
  }

  /// Starts (or restarts) the timer for one exercise. Any other running timer is stopped.
  void startExerciseTimer(String workoutId, int exerciseIndex) {
    final workout = _findWorkout(workoutId);
    if (workout == null || exerciseIndex < 0 || exerciseIndex >= workout.exercises.length) return;

    final seconds = workout.exercises[exerciseIndex].durationSeconds;
    if (seconds == null || seconds <= 0) return;

    _timer?.cancel();
    _activeWorkoutId = workoutId;
    _activeExerciseIndex = exerciseIndex;
    _pausedRemaining = null;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    _startTicking();
    onTimerTick?.call();
  }

  void _startTicking() {
    _timer?.cancel();
    // Ticks a few times a second; the remaining time is always computed from _endTime,
    // so it stays accurate even if ticks are delayed.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (remainingSeconds <= 0) {
        _finishActiveExercise();
      } else {
        onTimerTick?.call();
      }
    });
  }

  Future<void> _finishActiveExercise() async {
    _timer?.cancel();
    _timer = null;

    final workoutId = _activeWorkoutId;
    final index = _activeExerciseIndex;
    final workout = _findWorkout(workoutId);
    if (workoutId == null || index == null || workout == null || index >= workout.exercises.length) {
      stopTimer();
      return;
    }

    final finished = workout.exercises[index];
    final nextIndex = _nextTimedIndex(workout, index + 1);
    final next = nextIndex == -1 ? null : workout.exercises[nextIndex];

    // Move on right away instead of waiting for Firestore.
    if (nextIndex != -1) {
      startExerciseTimer(workoutId, nextIndex);
    } else {
      stopTimer();
    }
    onExerciseFinished?.call(finished, next);

    // updateExerciseCompleted toggles, so only call it if the user hasn't already checked it off.
    if (!finished.isCompleted) {
      await updateExerciseCompleted(workoutId, index);
      onTimerTick?.call();
    }
  }

  void pauseTimer() {
    if (_endTime == null || _pausedRemaining != null) return;
    _timer?.cancel();
    _timer = null;
    final remaining = _endTime!.difference(DateTime.now());
    _pausedRemaining = remaining.isNegative ? Duration.zero : remaining;
    onTimerTick?.call();
  }

  void resumeTimer() {
    if (_pausedRemaining == null) return;
    _endTime = DateTime.now().add(_pausedRemaining!);
    _pausedRemaining = null;
    _startTicking();
    onTimerTick?.call();
  }

  /// Adds (or with a negative number, removes) time from the active exercise.
  void addTime(int seconds) {
    if (_activeWorkoutId == null) return;
    final change = Duration(seconds: seconds);
    if (_pausedRemaining != null) {
      final updated = _pausedRemaining! + change;
      _pausedRemaining = updated.isNegative ? Duration.zero : updated;
    } else if (_endTime != null) {
      _endTime = _endTime!.add(change);
    }
    onTimerTick?.call();
  }

  /// Jumps to the next timed exercise without marking the current one complete.
  void skipExercise() {
    final workout = _findWorkout(_activeWorkoutId);
    final index = _activeExerciseIndex;
    if (workout == null || index == null) return;

    final nextIndex = _nextTimedIndex(workout, index + 1);
    if (nextIndex == -1) {
      stopTimer();
    } else {
      startExerciseTimer(workout.id!, nextIndex);
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _activeWorkoutId = null;
    _activeExerciseIndex = null;
    _endTime = null;
    _pausedRemaining = null;
    onTimerTick?.call();
  }
}
