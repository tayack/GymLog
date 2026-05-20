import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseTemplate {
  final String name;
  final int sets;
  final double weight;
  final int reps;

  ExerciseTemplate({
    required this.name,
    required this.sets,
    required this.weight,
    required this.reps,
  });

  factory ExerciseTemplate.fromMap(Map<String, dynamic> m) => ExerciseTemplate(
        name: m['name'] as String,
        sets: (m['sets'] as num).toInt(),
        weight: (m['weight'] as num).toDouble(),
        reps: (m['reps'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'weight': weight,
        'reps': reps,
      };

  ExerciseTemplate copyWith({String? name, int? sets, double? weight, int? reps}) =>
      ExerciseTemplate(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
      );
}

class MenuModel {
  final String? id;
  final String name;
  final List<ExerciseTemplate> exercises;

  MenuModel({
    this.id,
    required this.name,
    required this.exercises,
  });

  factory MenuModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MenuModel(
      id: doc.id,
      name: m['name'] as String,
      exercises: (m['exercises'] as List<dynamic>)
          .map((e) => ExerciseTemplate.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  MenuModel copyWith({String? id, String? name, List<ExerciseTemplate>? exercises}) =>
      MenuModel(
        id: id ?? this.id,
        name: name ?? this.name,
        exercises: exercises ?? this.exercises,
      );
}
