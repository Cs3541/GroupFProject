import 'package:advanced_bmi/advanced_bmi.dart';

abstract class UserInformation {
int get id;
String get name;
}

class BmrCalorieModelMetric implements UserInformation {
  @override
  final int id;
  @override
  final String name;

  BmrCalorieModelMetric ({
  required int id,
  required String name,
  required double weight,
  required double height,
  required int age,
  required String gender,
  required String activityLevel,
  double? waistCircumference,
  MeasurementSystem measurementSystem = MeasurementSystem.metric,
});
}

class BmrCalorieModelImperial implements UserInformation {
  @override
  final int id;
  @override
  final String name;

  BmrCalorieModelImperial({
  required int id = null,
  required String name = null,
  required double weight,
  required double height,
  required int age,
  required String gender,
  required String activityLevel,
  double? waistCircumference,
  MeasurementSystem measurementSystem = MeasurementSystem.imperial,
  })
}
