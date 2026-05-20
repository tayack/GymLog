import 'package:cloud_firestore/cloud_firestore.dart';

class SetEntry {
  final double weight;
  final int reps;
  bool done;

  SetEntry({required this.weight, required this.reps, this.done = false});

  factory SetEntry.fromMap(Map<String, dynamic> m) => SetEntry(
        weight: (m['weight'] as num).toDouble(),
        reps: (m['reps'] as num).toInt(),
        done: m['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'weight': weight, 'reps': reps, 'done': done};

  SetEntry copyWith({double? weight, int? reps, bool? done}) =>
      SetEntry(weight: weight ?? this.weight, reps: reps ?? this.reps, done: done ?? this.done);
}

class ExerciseSets {
  final String exercise;
  final List<SetEntry> entries;

  ExerciseSets({required this.exercise, required this.entries});

  factory ExerciseSets.fromMap(Map<String, dynamic> m) => ExerciseSets(
        exercise: m['exercise'] as String,
        entries: (m['entries'] as List<dynamic>)
            .map((e) => SetEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'exercise': exercise,
        'entries': entries.map((e) => e.toMap()).toList(),
      };
}

class WorkoutModel {
  final String? id;
  final DateTime date;
  final String menuName;
  final List<ExerciseSets> sets;

  WorkoutModel({
    this.id,
    required this.date,
    required this.menuName,
    required this.sets,
  });

  factory WorkoutModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      id: doc.id,
      date: (m['date'] as Timestamp).toDate(),
      menuName: m['menuName'] as String? ?? '',
      sets: (m['sets'] as List<dynamic>)
          .map((e) => ExerciseSets.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'menuName': menuName,
        'sets': sets.map((e) => e.toMap()).toList(),
      };

  double get totalVolume => sets
      .expand((ex) => ex.entries.where((e) => e.done))
      .fold(0.0, (acc, e) => acc + e.weight * e.reps);
}
