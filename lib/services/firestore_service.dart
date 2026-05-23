import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/menu_model.dart';
import '../models/workout_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _menus =>
      _db.collection('users').doc(_uid).collection('menus');
  CollectionReference get _workouts =>
      _db.collection('users').doc(_uid).collection('workouts');
  CollectionReference get _prs =>
      _db.collection('users').doc(_uid).collection('prs');

  // --- Menus ---
  Stream<List<MenuModel>> menusStream() => _menus.snapshots().map(
        (s) => s.docs.map((d) => MenuModel.fromDoc(d)).toList(),
      );

  Future<void> saveMenu(MenuModel menu) async {
    if (menu.id != null) {
      await _menus.doc(menu.id).set(menu.toMap());
    } else {
      await _menus.add(menu.toMap());
    }
  }

  Future<void> deleteMenu(String id) => _menus.doc(id).delete();

  // --- Workouts ---
  Stream<List<WorkoutModel>> workoutsStream() => _workouts
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => WorkoutModel.fromDoc(d)).toList());

  // --- PRs ---
  Stream<Map<String, SetEntry>> prsStream() => _prs.snapshots().map(
        (s) => {
          for (final doc in s.docs)
            doc.id: SetEntry(
              weight: ((doc.data() as Map<String, dynamic>)['weight'] as num)
                  .toDouble(),
              reps: ((doc.data() as Map<String, dynamic>)['reps'] as num)
                  .toInt(),
            )
        },
      );

  // 返り値: 既存PRを上回った種目名 → 新記録エントリ のMap
  Future<Map<String, SetEntry>> _updatePRsForWorkout(WorkoutModel workout) async {
    final newPRs = <String, SetEntry>{};
    for (final ex in workout.sets) {
      if (ex.entries.isEmpty) continue;
      final best = ex.entries.reduce((a, b) =>
          a.weight > b.weight
              ? a
              : (a.weight == b.weight && a.reps > b.reps ? a : b));
      final prRef = _prs.doc(ex.exercise);
      final snap = await prRef.get();
      if (!snap.exists) {
        await prRef.set({'weight': best.weight, 'reps': best.reps});
      } else {
        final data = snap.data() as Map<String, dynamic>;
        final w = (data['weight'] as num).toDouble();
        final r = (data['reps'] as num).toInt();
        if (best.weight > w || (best.weight == w && best.reps > r)) {
          await prRef.set({'weight': best.weight, 'reps': best.reps});
          newPRs[ex.exercise] = best;
        }
      }
    }
    return newPRs;
  }

  // 削除後にPRを全ワークアウトから再計算する
  Future<void> recalcPRsForExercises(List<String> exerciseNames) async {
    final snap = await _workouts.get();
    final workouts = snap.docs.map((d) => WorkoutModel.fromDoc(d)).toList();
    for (final name in exerciseNames) {
      SetEntry? best;
      for (final w in workouts) {
        for (final ex in w.sets) {
          if (ex.exercise != name) continue;
          for (final entry in ex.entries) {
            if (best == null ||
                entry.weight > best.weight ||
                (entry.weight == best.weight && entry.reps > best.reps)) {
              best = entry;
            }
          }
        }
      }
      final prRef = _prs.doc(name);
      if (best == null) {
        await prRef.delete();
      } else {
        await prRef.set({'weight': best.weight, 'reps': best.reps});
      }
    }
  }

  // --- Workouts ---
  Future<Map<String, SetEntry>> saveWorkout(WorkoutModel workout) async {
    await _workouts.add(workout.toMap());
    return _updatePRsForWorkout(workout);
  }

  Future<void> updateWorkout(WorkoutModel workout) =>
      _workouts.doc(workout.id).set(workout.toMap());

  Future<void> deleteWorkout(String id) => _workouts.doc(id).delete();

  // アカウント削除前にFirestore上のデータを全消去する
  Future<void> deleteAllUserData() async {
    final menuSnap = await _menus.get();
    for (final doc in menuSnap.docs) {
      await doc.reference.delete();
    }
    final workoutSnap = await _workouts.get();
    for (final doc in workoutSnap.docs) {
      await doc.reference.delete();
    }
    final prSnap = await _prs.get();
    for (final doc in prSnap.docs) {
      await doc.reference.delete();
    }
    await _db.collection('users').doc(_uid).delete();
  }

  Future<SetEntry?> getLastEntryForExercise(String exerciseName) async {
    final snap = await _workouts
        .orderBy('date', descending: true)
        .limit(20)
        .get();
    for (final doc in snap.docs) {
      final w = WorkoutModel.fromDoc(doc);
      for (final ex in w.sets) {
        if (ex.exercise == exerciseName && ex.entries.isNotEmpty) {
          return ex.entries.first;
        }
      }
    }
    return null;
  }
}
