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

  Future<void> saveWorkout(WorkoutModel workout) => _workouts.add(workout.toMap());

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
