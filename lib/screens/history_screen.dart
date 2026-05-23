import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/strings.dart';
import '../models/workout_model.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wheel_picker.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _fs = FirestoreService();
  int _page = 0;

  void _openEditPage(WorkoutModel workout) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _WorkoutEditPage(workout: workout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return StreamBuilder<List<WorkoutModel>>(
      stream: _fs.workoutsStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kRed));
        }
        final all = snap.data ?? [];
        if (all.isEmpty) {
          return Center(
            child: Text(s.noHistory,
                style: const TextStyle(color: kTextDim, letterSpacing: 1.5)),
          );
        }

        const pageSize = 10;
        final totalPages = ((all.length - 1) ~/ pageSize) + 1;
        final safePage = _page.clamp(0, totalPages - 1);
        final start = safePage * pageSize;
        final end = (start + pageSize).clamp(0, all.length);
        final pageData = all.sublist(start, end);

        final exercises = <String>{};
        for (final w in pageData) {
          for (final es in w.sets) {
            exercises.add(es.exercise);
          }
        }
        final exList = exercises.toList();

        return StreamBuilder<Map<String, SetEntry>>(
          stream: _fs.prsStream(),
          builder: (ctx2, prSnap) {
            final prs = prSnap.data ?? {};
            return _buildContent(context, s, pageData, exList, safePage,
                totalPages, prs);
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppStrings s,
    List<WorkoutModel> pageData,
    List<String> exList,
    int safePage,
    int totalPages,
    Map<String, SetEntry> prs,
  ) {
    return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(s.history,
                      style: const TextStyle(
                          fontSize: 10, color: kTextMuted, letterSpacing: 3)),
                  const Spacer(),
                  _PageBtn(
                    icon: Icons.chevron_left,
                    enabled: safePage < totalPages - 1,
                    onTap: () => setState(() => _page = safePage + 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${safePage + 1}/$totalPages',
                        style: const TextStyle(
                            fontSize: 10,
                            color: kTextMuted,
                            letterSpacing: 1)),
                  ),
                  _PageBtn(
                    icon: Icons.chevron_right,
                    enabled: safePage > 0,
                    onTap: () => setState(() => _page = safePage - 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    border: TableBorder.all(color: kBorder, width: 1),
                    children: [
                      // ヘッダー行
                      TableRow(
                        decoration: const BoxDecoration(color: kSurface),
                        children: [
                          _tCell(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(s.exerciseCol,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: kTextMuted,
                                    letterSpacing: 2)),
                          ),
                          _tCell(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(s.prLabel,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: kTextMuted,
                                    letterSpacing: 2)),
                          ),
                          ...pageData.map((w) => _tCell(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: GestureDetector(
                                  onTap: () => _openEditPage(w),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: kRed.withValues(alpha: 0.5)),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('MM/dd(E)', s.languageCode)
                                              .format(w.date),
                                          style: const TextStyle(
                                              fontSize: 10, color: kRed),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit,
                                            size: 11, color: kRed),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                      // データ行（行の高さはコンテンツに応じて動的に変化）
                      ...exList.map((ex) {
                        final pr = prs[ex];
                        final prText = pr == null
                            ? '—'
                            : '${pr.weight % 1 == 0 ? pr.weight.toInt() : pr.weight}×${pr.reps}';
                        return TableRow(
                            decoration: const BoxDecoration(color: kBg),
                            children: [
                              _tCell(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Text(ex,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFAAAAAA))),
                              ),
                              _tCell(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Text(prText,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: pr != null ? kRed : const Color(0xFF2A2A2E),
                                        fontWeight: pr != null
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ),
                              ...pageData.map((w) {
                                final exData = w.sets
                                    .where((es) => es.exercise == ex)
                                    .firstOrNull;
                                return _tCell(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: exData == null
                                      ? const Text('—',
                                          style: TextStyle(
                                              color: Color(0xFF2A2A2E),
                                              fontSize: 10))
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: exData.entries
                                              .map((e) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 2),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text('${e.weight}',
                                                            style: const TextStyle(
                                                                color: kRed,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        Text('×${e.reps}',
                                                            style: const TextStyle(
                                                                color:
                                                                    kTextMuted,
                                                                fontSize: 9)),
                                                      ],
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                );
                              }),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
  }
}

// ── 履歴編集ページ ─────────────────────────────────────────────────────────────

class _WorkoutEditPage extends StatefulWidget {
  final WorkoutModel workout;
  const _WorkoutEditPage({required this.workout});

  @override
  State<_WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<_WorkoutEditPage> {
  final _fs = FirestoreService();
  late List<ExerciseSets> _sets;
  bool _saving = false;

  AppStrings get _s => context.read<LocaleProvider>().s;

  @override
  void initState() {
    super.initState();
    _sets = widget.workout.sets
        .map((es) => ExerciseSets(
              exercise: es.exercise,
              entries: es.entries
                  .map((e) =>
                      SetEntry(weight: e.weight, reps: e.reps, done: e.done))
                  .toList(),
            ))
        .toList();
  }

  void _updateEntry(int exIdx, int entryIdx, {double? weight, int? reps}) {
    setState(() {
      final e = _sets[exIdx].entries[entryIdx];
      _sets[exIdx].entries[entryIdx] = e.copyWith(weight: weight, reps: reps);
    });
  }

  void _removeEntry(int exIdx, int entryIdx) {
    setState(() {
      _sets[exIdx].entries.removeAt(entryIdx);
      if (_sets[exIdx].entries.isEmpty) _sets.removeAt(exIdx);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = _s;
    try {
      await _fs.updateWorkout(WorkoutModel(
        id: widget.workout.id,
        date: widget.workout.date,
        menuName: widget.workout.menuName,
        sets: _sets,
      ));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
            content: Text(s.workoutUpdated), backgroundColor: kRed));
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _share() {
    final s = _s;
    final dateStr = DateFormat('yyyy/MM/dd(E)', s.languageCode)
        .format(widget.workout.date);
    final lines = [dateStr];
    if (widget.workout.menuName.isNotEmpty) lines.add(widget.workout.menuName);
    for (final ex in _sets) {
      if (ex.entries.isEmpty) continue;
      lines.add('${ex.exercise}: '
          '${ex.entries.map((e) => '${e.weight}kg×${e.reps}').join(', ')}');
    }
    final vol = _sets
        .expand((ex) => ex.entries)
        .fold(0.0, (acc, e) => acc + e.weight * e.reps);
    if (vol > 0) {
      lines.add(
          '${s.languageCode == 'ja' ? '総ボリューム' : 'Total Volume'}: '
          '${NumberFormat('#,###').format(vol.toInt())}kg');
    }
    Share.share(lines.join('\n'));
  }

  Future<void> _confirmDelete() async {
    final s = _s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.deleteWorkout, style: const TextStyle(color: kText)),
        content: Text(s.deleteWorkoutConfirm,
            style: const TextStyle(
                color: kTextDim, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirm == true && widget.workout.id != null && mounted) {
      final exerciseNames = widget.workout.sets.map((ex) => ex.exercise).toList();
      await _fs.deleteWorkout(widget.workout.id!);
      await _fs.recalcPRsForExercises(exerciseNames);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    final dateStr = DateFormat('yyyy/MM/dd(E)', s.languageCode)
        .format(widget.workout.date);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dateStr,
                style: const TextStyle(
                    fontSize: 11, color: kTextDim, letterSpacing: 1)),
            if (widget.workout.menuName.isNotEmpty)
              Text(widget.workout.menuName,
                  style: const TextStyle(
                      fontSize: 16,
                      color: kRed,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 18, color: kTextDim),
            onPressed: _share,
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? s.saving : s.save,
              style: const TextStyle(color: kRed, letterSpacing: 1),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._sets.asMap().entries.map((e) => _EditExerciseCard(
                key: ValueKey(e.key),
                exSets: e.value,
                exIdx: e.key,
                onUpdateEntry: _updateEntry,
                onRemoveEntry: _removeEntry,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: Text(s.deleteWorkout,
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 1.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kRed,
                side: const BorderSide(color: kRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── セット編集カード ───────────────────────────────────────────────────────────

class _EditExerciseCard extends StatelessWidget {
  final ExerciseSets exSets;
  final int exIdx;
  final void Function(int, int, {double? weight, int? reps}) onUpdateEntry;
  final void Function(int, int) onRemoveEntry;

  const _EditExerciseCard({
    super.key,
    required this.exSets,
    required this.exIdx,
    required this.onUpdateEntry,
    required this.onRemoveEntry,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
                child: Text(exSets.exercise,
                    style: const TextStyle(
                        fontSize: 12, letterSpacing: 1.5, color: kText))),
          ]),
        ),
        const Divider(height: 1, color: kBorder),
        ...exSets.entries.asMap().entries.map((e) {
          final entry = e.value;
          final idx = e.key;
          return Container(
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
                  style:
                      TextStyle(color: Color(0xFF444444), fontSize: 12)),
              const SizedBox(width: 4),
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
              GestureDetector(
                onTap: () => onRemoveEntry(exIdx, idx),
                child: const Icon(Icons.close,
                    color: kTextMuted, size: 18),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── テーブルセル ──────────────────────────────────────────────────────────────

Widget _tCell({required Widget child, required EdgeInsets padding}) =>
    TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(padding: padding, child: child),
    );

// ── ページネーションボタン ─────────────────────────────────────────────────────

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: kBorderDim),
          borderRadius: BorderRadius.circular(3),
        ),
        child:
            Icon(icon, size: 16, color: enabled ? kTextDim : kTextMuted),
      ),
    );
  }
}
