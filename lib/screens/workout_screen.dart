import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../l10n/exercises.dart';
import '../l10n/strings.dart';
import '../models/menu_model.dart';
import '../models/workout_model.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/wheel_picker.dart';

class WorkoutScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const WorkoutScreen({super.key, required this.onTabChange});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _fs = FirestoreService();
  MenuModel? _selectedMenu;
  List<ExerciseSets> _sets = [];
  final _addCtrl = TextEditingController();
  bool _saving = false;

  AppStrings get _s => context.read<LocaleProvider>().s;

  void _startWorkout(MenuModel menu) async {
    final sets = <ExerciseSets>[];
    for (final ex in menu.exercises) {
      final last = await _fs.getLastEntryForExercise(ex.name);
      sets.add(ExerciseSets(
        exercise: ex.name,
        entries: List.generate(ex.sets, (i) => SetEntry(
          weight: last?.weight ?? ex.weight,
          reps:   last?.reps   ?? ex.reps,
        )),
      ));
    }
    setState(() { _selectedMenu = menu; _sets = sets; });
  }

  void _startAdhoc() => setState(() {
    _selectedMenu = MenuModel(name: _s.startAdhoc, exercises: []);
    _sets = [];
  });

  Future<void> _cancelWorkout() async {
    final s = _s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.cancelWorkoutTitle,
            style: const TextStyle(color: kText)),
        content: Text(s.cancelWorkoutBody,
            style: const TextStyle(
                color: kTextDim, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.discard),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() { _selectedMenu = null; _sets = []; });
    }
  }

  void _addExercise(String name) async {
    if (name.trim().isEmpty) return;
    final last = await _fs.getLastEntryForExercise(name.trim());
    setState(() {
      _sets.add(ExerciseSets(
        exercise: name.trim(),
        entries: [SetEntry(weight: last?.weight ?? 20, reps: last?.reps ?? 10)],
      ));
      _addCtrl.clear();
    });
  }

  void _addSet(int exIdx) => setState(() {
    final last = _sets[exIdx].entries.last;
    _sets[exIdx].entries.add(SetEntry(weight: last.weight, reps: last.reps));
  });

  Future<void> _toggleDone(int exIdx, int entryIdx) async {
    final wasDone = _sets[exIdx].entries[entryIdx].done;
    setState(() {
      final e = _sets[exIdx].entries[entryIdx];
      _sets[exIdx].entries[entryIdx] = e.copyWith(done: !e.done);
    });
    if (!wasDone) {
      final lp = context.read<LocaleProvider>();
      final s = lp.s;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: kSurface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        builder: (_) => _IntervalTimerSheet(
          exerciseName: _sets[exIdx].exercise,
          initialSeconds: lp.intervalDefault,
          notifBody: s.notifTimerBody,
          notifChannelName: s.notifChannelName,
          notifChannelDesc: s.notifChannelDesc,
        ),
      );
      if (mounted && _allDone()) await _showCompletionFlow();
    }
  }

  bool _allDone() =>
      _sets.isNotEmpty &&
      _sets.every((ex) => ex.entries.isNotEmpty && ex.entries.every((e) => e.done));

  void _updateEntry(int exIdx, int entryIdx, {double? weight, int? reps}) =>
      setState(() {
        final e = _sets[exIdx].entries[entryIdx];
        _sets[exIdx].entries[entryIdx] = e.copyWith(weight: weight, reps: reps);
      });

  Future<Map<String, SetEntry>> _saveWorkout() async {
    setState(() => _saving = true);
    final workout = WorkoutModel(
      date: DateTime.now(),
      menuName: _selectedMenu?.name ?? '',
      sets: _sets
          .map((ex) => ExerciseSets(
                exercise: ex.exercise,
                entries: ex.entries.where((e) => e.done).toList(),
              ))
          .where((ex) => ex.entries.isNotEmpty)
          .toList(),
    );
    final newPRs = await _fs.saveWorkout(workout);
    setState(() => _saving = false);
    return newPRs;
  }

  void _clearWorkout() => setState(() { _selectedMenu = null; _sets = []; });

  // PR達成時の演出 + ルーティン更新確認ダイアログ
  Future<void> _showPrAndRoutineDialog(
      Map<String, SetEntry> newPRs, MenuModel? menu) async {
    if (!mounted || newPRs.isEmpty) return;
    final s = _s;

    final prLines = newPRs.entries.map((e) {
      final w = e.value.weight % 1 == 0
          ? '${e.value.weight.toInt()}'
          : '${e.value.weight}';
      return '${e.key}  ${w}kg × ${e.value.reps}rep';
    }).join('\n');

    final hasUpdatableRoutine = menu?.id != null &&
        menu!.exercises.any((ex) => newPRs.containsKey(ex.name));

    if (hasUpdatableRoutine) {
      final update = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text(s.prAchievedTitle,
              style: const TextStyle(color: kText, fontSize: 18)),
          content: Text(
            '$prLines\n\n${s.updateRoutineBody(menu.name)}',
            style: const TextStyle(color: kTextDim, fontSize: 13, height: 1.6),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: kRed),
              child: Text(s.updateRoutine),
            ),
          ],
        ),
      );
      if (update == true && mounted) {
        final updated = menu.copyWith(
          exercises: menu.exercises.map((ex) {
            final pr = newPRs[ex.name];
            return pr == null ? ex : ex.copyWith(weight: pr.weight, reps: pr.reps);
          }).toList(),
        );
        await _fs.saveMenu(updated);
      }
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text(s.prAchievedTitle,
              style: const TextStyle(color: kText, fontSize: 18)),
          content: Text(prLines,
              style: const TextStyle(color: kTextDim, fontSize: 13, height: 1.6)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: kRed),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _finish() async {
    final menu = _selectedMenu;
    final newPRs = await _saveWorkout();
    _clearWorkout();
    if (!mounted) return;
    await _showPrAndRoutineDialog(newPRs, menu);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_s.workoutSaved), backgroundColor: kRed,
        duration: const Duration(seconds: 2)));
    widget.onTabChange(1);
  }

  Future<void> _showCompletionFlow() async {
    if (!mounted) return;
    final s = _s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.workoutCompleteTitle,
            style: const TextStyle(color: kText)),
        content: Text(s.workoutCompleteBody,
            style: const TextStyle(color: kTextDim, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final shareText = _buildShareText();
    final menu = _selectedMenu;
    final newPRs = await _saveWorkout();
    _clearWorkout();
    if (!mounted) return;
    await _showPrAndRoutineDialog(newPRs, menu);
    if (!mounted) return;
    final doShare = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.sharePrompt,
            style: const TextStyle(color: kText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.share),
          ),
        ],
      ),
    );
    if (doShare == true) Share.share(shareText);
    if (mounted) widget.onTabChange(1);
  }

  String _buildShareText() {
    final s = _s;
    final today = DateFormat('yyyy/MM/dd(E)', s.languageCode).format(DateTime.now());
    final lines = [today];
    for (final ex in _sets) {
      final done = ex.entries.where((e) => e.done).toList();
      if (done.isEmpty) continue;
      lines.add('${ex.exercise}: ${done.map((e) => '${e.weight}kg×${e.reps}').join(', ')}');
    }
    final vol = _sets.expand((ex) => ex.entries.where((e) => e.done))
        .fold(0.0, (acc, e) => acc + e.weight * e.reps);
    lines.add('${s.languageCode == 'ja' ? '総ボリューム' : 'Total Volume'}: ${NumberFormat('#,###').format(vol.toInt())}kg');
    return lines.join('\n');
  }

  void _share() => Share.share(_buildShareText());

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>(); // rebuild on locale change
    return _selectedMenu == null ? _buildMenuSelect() : _buildWorkout();
  }

  Widget _buildMenuSelect() {
    final s = _s;
    return StreamBuilder<List<MenuModel>>(
      stream: _fs.menusStream(),
      builder: (ctx, snap) {
        final menus = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.selectRoutine.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, color: kTextMuted, letterSpacing: 3)),
            const SizedBox(height: 12),
            if (menus.isEmpty) _buildEmptyRoutineState(s),
            ...menus.map((m) => _MenuCard(menu: m, onTap: () => _startWorkout(m))),
            const SizedBox(height: 8),
            _DashedButton(label: s.startAdhoc, onTap: _startAdhoc),
          ],
        );
      },
    );
  }

  Widget _buildEmptyRoutineState(AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: kBorderDim),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.noRoutines,
            style: const TextStyle(
                fontSize: 13, color: kText, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(s.noRoutinesHint,
            style: const TextStyle(
                fontSize: 11, color: kTextDim, height: 1.6)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => widget.onTabChange(2),
          child: Text(s.goToRoutines,
              style: const TextStyle(
                  fontSize: 12, color: kRed, letterSpacing: 1)),
        ),
      ]),
    );
  }

  Widget _buildWorkout() {
    final s = _s;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close, color: kTextDim, size: 20),
            onPressed: _cancelWorkout,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TODAY',
                style: TextStyle(fontSize: 9, color: kTextMuted, letterSpacing: 3)),
            Text(_selectedMenu!.name,
                style: const TextStyle(
                    fontSize: 20, color: kRed, letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
          ])),
          TextButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share, size: 14),
            label: Text(s.share,
                style: const TextStyle(fontSize: 11, letterSpacing: 1.5)),
            style: TextButton.styleFrom(
              foregroundColor: kTextDim,
              backgroundColor: kSurface,
              side: const BorderSide(color: kBorderDim),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saving ? null : _finish,
            child: Text(_saving ? s.saving : s.save),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._sets.asMap().entries.map((e) => _ExerciseCard(
                  key: ValueKey(e.key),
                  exSets: e.value,
                  exIdx: e.key,
                  onToggleDone: _toggleDone,
                  onUpdateEntry: _updateEntry,
                  onAddSet: _addSet,
                  fs: _fs,
                )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: _addCtrl,
                  focusNode: FocusNode(),
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) return const [];
                    final exercises =
                        getExercises(context.read<LocaleProvider>().s.languageCode);
                    final q = normalizeForSearch(v.text);
                    return exercises.where((e) =>
                        normalizeForSearch(e).contains(q) &&
                        !_sets.any((s) => s.exercise == e));
                  },
                  onSelected: _addExercise,
                  fieldViewBuilder: (ctx, ctrl, fn, _) => TextField(
                    controller: ctrl,
                    focusNode: fn,
                    style: const TextStyle(color: kText, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: s.addExercisePlaceholder,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _addExercise,
                  ),
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: kSurface,
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: opts
                              .map((o) => ListTile(
                                    dense: true,
                                    title: Text(o,
                                        style: const TextStyle(
                                            color: kText, fontSize: 12)),
                                    onTap: () => onSel(o),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addExercise(_addCtrl.text),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(44, 44), padding: EdgeInsets.zero),
                child: const Icon(Icons.add),
              ),
            ]),
          ],
        ),
      ),
    ]);
  }
}

// ── 種目カード ────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseSets exSets;
  final int exIdx;
  final FirestoreService fs;
  final void Function(int, int) onToggleDone;
  final void Function(int, int, {double? weight, int? reps}) onUpdateEntry;
  final void Function(int) onAddSet;

  const _ExerciseCard({
    super.key,
    required this.exSets,
    required this.exIdx,
    required this.fs,
    required this.onToggleDone,
    required this.onUpdateEntry,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.read<LocaleProvider>().s;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: kSurface,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        // ヘッダー：種目名 ＋ 前回値
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
                child: Text(exSets.exercise,
                    style: const TextStyle(
                        fontSize: 12, letterSpacing: 1.5, color: kText))),
            FutureBuilder<SetEntry?>(
              future: fs.getLastEntryForExercise(exSets.exercise),
              builder: (_, snap) {
                if (!snap.hasData || snap.data == null) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${s.prevLabel} ${snap.data!.weight}kg×${snap.data!.reps}',
                  style: const TextStyle(fontSize: 10, color: kTextMuted),
                );
              },
            ),
          ]),
        ),
        const Divider(height: 1, color: kBorder),
        // セット行
        ...exSets.entries.asMap().entries.map((e) {
          final entry = e.value;
          final idx = e.key;
          return Opacity(
            opacity: entry.done ? 0.5 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                border: idx < exSets.entries.length - 1
                    ? const Border(
                        bottom: BorderSide(color: Color(0xFF131316)))
                    : null,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                SizedBox(
                  width: 22,
                  child: Text('#${idx + 1}',
                      style: const TextStyle(
                          fontSize: 9, color: kTextMuted, letterSpacing: 1)),
                ),
                // 重量タップで選択
                WheelFieldTile(
                  value: entry.weight % 1 == 0
                      ? '${entry.weight.toInt()}'
                      : '${entry.weight}',
                  unit: 'kg',
                  onTap: () async {
                    final v = await showWeightPicker(
                        context, entry.weight, s.selectWeight, s.done);
                    if (v != null) onUpdateEntry(exIdx, idx, weight: v);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('kg',
                      style: TextStyle(fontSize: 10, color: kTextMuted)),
                ),
                const Text('×',
                    style: TextStyle(color: Color(0xFF444444), fontSize: 12)),
                const SizedBox(width: 4),
                // 回数タップで選択
                WheelFieldTile(
                  value: '${entry.reps}',
                  unit: 'rep',
                  onTap: () async {
                    final v = await showRepsPicker(
                        context, entry.reps, s.selectReps, s.done);
                    if (v != null) onUpdateEntry(exIdx, idx, reps: v);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('rep',
                      style: TextStyle(fontSize: 10, color: kTextMuted)),
                ),
                const Spacer(),
                // 完了ボタン
                GestureDetector(
                  onTap: () => onToggleDone(exIdx, idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.done ? kRed : Colors.transparent,
                      border: Border.all(
                          color: entry.done ? kRed : const Color(0xFF2A2A2E),
                          width: 2),
                    ),
                    child: entry.done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ]),
            ),
          );
        }),
        TextButton(
          onPressed: () => onAddSet(exIdx),
          style: TextButton.styleFrom(
            foregroundColor: kTextMuted,
            minimumSize: const Size(double.infinity, 36),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(s.addSet,
              style: const TextStyle(fontSize: 11, letterSpacing: 2)),
        ),
      ]),
    );
  }
}

// ── 汎用ウィジェット ──────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onTap;
  const _MenuCard({required this.menu, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kSurface,
            border: Border.all(color: kBorderDim),
            borderRadius: BorderRadius.circular(4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(menu.name,
              style: const TextStyle(
                  fontSize: 18, color: kRed, letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(menu.exercises.map((e) => e.name).join(' · '),
              style: const TextStyle(fontSize: 11, color: kTextDim)),
        ]),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2A2A2E)),
            borderRadius: BorderRadius.circular(4)),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: kTextMuted, fontSize: 12, letterSpacing: 2)),
        ),
      ),
    );
  }
}

// ── インターバルタイマーシート ─────────────────────────────────────────────────

class _IntervalTimerSheet extends StatefulWidget {
  final String exerciseName;
  final int initialSeconds;
  final String notifBody;
  final String notifChannelName;
  final String notifChannelDesc;

  const _IntervalTimerSheet({
    required this.exerciseName,
    required this.initialSeconds,
    required this.notifBody,
    required this.notifChannelName,
    required this.notifChannelDesc,
  });

  @override
  State<_IntervalTimerSheet> createState() => _IntervalTimerSheetState();
}

String _fmtPreset(int secs) {
  final m = secs ~/ 60;
  final s = secs % 60;
  if (m == 0) return '${s}s';
  if (s == 0) return '${m}m';
  return '${m}m${s}s';
}

class _IntervalTimerSheetState extends State<_IntervalTimerSheet> {
  static const _presets = [30, 60, 90, 120, 150, 180];
  late int _total;
  late int _remaining;
  bool _done = false;
  Timer? _timer;

  final _notif = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _total = widget.initialSeconds;
    _remaining = widget.initialSeconds;
    _initNotif();
    _startTimer();
  }

  Future<void> _initNotif() async {
    await _notif.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    // Android 13+ requires runtime permission for notifications
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _startTimer() {
    _timer?.cancel();
    _done = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _done = true;
          t.cancel();
          _onComplete();
        }
      });
    });
  }

  void _selectPreset(int secs) {
    _timer?.cancel();
    setState(() { _total = secs; _remaining = secs; _done = false; });
    _startTimer();
  }

  Future<void> _onComplete() async {
    final hasVib = await Vibration.hasVibrator();
    if (hasVib == true) {
      await Vibration.vibrate(pattern: [0, 500, 150, 500, 150, 800]);
    }
    await _notif.show(
      1,
      'GYMLOG',
      widget.notifBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel_v2',
          widget.notifChannelName,
          channelDescription: widget.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 150, 500, 150, 800]),
          playSound: true,
          ticker: widget.notifBody,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _remaining / _total : 0.0;
    final s = context.read<LocaleProvider>().s;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: kBorderDim, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(s.intervalTimer,
                style: const TextStyle(
                    fontSize: 11, color: kRed, letterSpacing: 3,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.exerciseName.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, color: kTextMuted, letterSpacing: 2),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFF1A1A1F),
                    valueColor: AlwaysStoppedAnimation(
                        _done ? const Color(0xFF444444) : kRed),
                  ),
                ),
                Text(
                  _fmt(_remaining),
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _done ? kTextDim : kText,
                      letterSpacing: 3),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final selected = _total == p;
                return GestureDetector(
                  onTap: () => _selectPreset(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? kRed : Colors.transparent,
                      border:
                          Border.all(color: selected ? kRed : kBorderDim),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _fmtPreset(p),
                      style: TextStyle(
                          fontSize: 11,
                          color: selected ? Colors.white : kTextMuted,
                          letterSpacing: 1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(s.intervalDefaultHint,
                style: const TextStyle(
                    fontSize: 9, color: kTextMuted, letterSpacing: 0.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _done ? kRed : kTextMuted,
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF1A1A1F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _done ? 'OK' : 'SKIP',
                style: const TextStyle(fontSize: 14, letterSpacing: 3),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }
}
