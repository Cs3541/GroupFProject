// Pure Models for goals
abstract class Goal {
  String get id;
  String get title;
  bool get isCompleted;
}

class MetricGoal implements Goal {
  @override
  final String id;
  @override
  final String title;

  final double targetMiles;
  final double currentMiles;

  MetricGoal({
    required this.id,
    required this.title,
    required this.targetMiles,
    this.currentMiles = 0.0,
  });

  @override
  bool get isCompleted => currentMiles >= targetMiles;
}

class HabitGoal implements Goal {
  @override
  final String id;
  @override
  final String title;
  @override
  final bool isCompleted;

  HabitGoal({required this.id, required this.title, this.isCompleted = false});
}
