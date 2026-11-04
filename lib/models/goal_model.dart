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

  final double targetValue;
  final double currentValue;
  final String unit;

  MetricGoal({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    this.unit = '',
  });

  @override
  bool get isCompleted => currentValue >= targetValue;
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
