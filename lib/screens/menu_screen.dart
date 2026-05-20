import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/exercises.dart';
import '../models/menu_model.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wheel_picker.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _fs = FirestoreService();
  MenuModel? _editing;
  TextEditingController? _nameCtrl;

  @override
  void dispose() {
    _nameCtrl?.dispose();
    super.dispose();
  }

  void _startNew() {
    _nameCtrl?.dispose();
    _nameCtrl = TextEditingController();
    setState(() => _editing = MenuModel(name: '', exercises: []));
  }

  void _startEdit(MenuModel m) {
    _nameCtrl?.dispose();
    _nameCtrl = TextEditingController(text: m.name);
    setState(() => _editing = m);
  }

  void _cancel() {
    _nameCtrl?.dispose();
    _nameCtrl = null;
    setState(() => _editing = null);
  }

  Future<void> _save() async {
    final s = context.read<LocaleProvider>().s;
    if (_editing == null || _editing!.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.routineNameRequired),
        backgroundColor: kRed,
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    try {
      await _fs.saveMenu(_editing!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: kRed,
        duration: const Duration(seconds: 4),
      ));
      return;
    }
    if (!mounted) return;
    _nameCtrl?.dispose();
    _nameCtrl = null;
    setState(() => _editing = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.routineSaved,
          style: const TextStyle(letterSpacing: 1.5)),
      backgroundColor: kRed,
      duration: const Duration(seconds: 2),
    ));
  }

  String _fmtPreset(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m${s}s';
  }

  Future<void> _showIntervalDefaultPicker() async {
    final lp = context.read<LocaleProvider>();
    final s = lp.s;
    const presets = [30, 60, 90, 120, 150, 180];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final current = context.read<LocaleProvider>().intervalDefault;
          return AlertDialog(
            backgroundColor: kSurface,
            title: Text(s.intervalDefault,
                style: const TextStyle(
                    color: kText, fontSize: 14, letterSpacing: 1)),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final selected = current == p;
                final label = _fmtPreset(p);
                return GestureDetector(
                  onTap: () async {
                    await lp.setIntervalDefault(p);
                    setDlg(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? kRed : Colors.transparent,
                      border: Border.all(
                          color: selected ? kRed : kBorderDim),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            color: selected ? Colors.white : kTextMuted,
                            letterSpacing: 1)),
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.done)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(MenuModel m) async {
    final s = context.read<LocaleProvider>().s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.deleteConfirm, style: const TextStyle(color: kText)),
        content: Text(s.deleteMsg(m.name),
            style: const TextStyle(color: kTextDim)),
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
    if (confirm == true && m.id != null) {
      await _fs.deleteMenu(m.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing != null) return _buildEditor();
    return _buildList();
  }

  Widget _buildList() {
    final lp = context.watch<LocaleProvider>();
    final s = lp.s;
    final intervalSecs = lp.intervalDefault;
    return StreamBuilder<List<MenuModel>>(
      stream: _fs.menusStream(),
      builder: (ctx, snap) {
        final menus = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(s.routinesDesc,
                  style: const TextStyle(
                      fontSize: 11,
                      color: kTextDim,
                      height: 1.6,
                      letterSpacing: 0.3)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showIntervalDefaultPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurface,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  const Icon(Icons.timer_outlined,
                      color: kTextDim, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.intervalDefault,
                        style: const TextStyle(
                            fontSize: 13,
                            color: kText,
                            letterSpacing: 0.5)),
                  ),
                  Text(_fmtPreset(intervalSecs),
                      style: const TextStyle(
                          fontSize: 16,
                          color: kRed,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: kBorderDim, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(s.tabRoutines.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, color: kTextMuted, letterSpacing: 3)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _startNew,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7)),
                  child: Text(s.newRoutine,
                      style:
                          const TextStyle(fontSize: 11, letterSpacing: 1.5)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (menus.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(s.noRoutinesDesc,
                      style: const TextStyle(
                          color: kTextDim, letterSpacing: 1.5)),
                ),
              ),
            ...menus.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface,
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(m.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: kRed,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold)),
                          ),
                          OutlinedButton(
                            onPressed: () => _startEdit(m),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextDim,
                              side: const BorderSide(color: kBorderDim),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              textStyle: const TextStyle(
                                  fontSize: 10, letterSpacing: 1.5),
                            ),
                            child: Text(s.edit),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _delete(m),
                            icon: const Icon(Icons.delete_outline,
                                color: kTextMuted, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...m.exercises.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ex.name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF777777))),
                                Text(
                                    '${ex.sets}sets × ${ex.weight}kg × ${ex.reps}rep',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF777777))),
                              ],
                            ),
                          )),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEditor() {
    final s = context.watch<LocaleProvider>().s;
    final isNew = _editing!.id == null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(isNew ? s.newRoutineLabel : s.editRoutineLabel,
                style: const TextStyle(
                    fontSize: 10, color: kTextMuted, letterSpacing: 3)),
            const Spacer(),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextDim,
                side: const BorderSide(color: kBorderDim),
              ),
              child: Text(s.cancel, style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(
              color: kText,
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(hintText: s.routineNameHint),
          onChanged: (v) => _editing = _editing!.copyWith(name: v),
        ),
        const SizedBox(height: 12),
        ..._editing!.exercises.asMap().entries.map((e) => _ExerciseEditRow(
              key: ValueKey(e.key),
              ex: e.value,
              onChanged: (updated) {
                final exs =
                    List<ExerciseTemplate>.from(_editing!.exercises);
                exs[e.key] = updated;
                setState(
                    () => _editing = _editing!.copyWith(exercises: exs));
              },
              onDelete: () {
                final exs =
                    List<ExerciseTemplate>.from(_editing!.exercises);
                exs.removeAt(e.key);
                setState(
                    () => _editing = _editing!.copyWith(exercises: exs));
              },
            )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final exs =
                List<ExerciseTemplate>.from(_editing!.exercises);
            exs.add(
                ExerciseTemplate(name: '', sets: 3, weight: 20, reps: 10));
            setState(
                () => _editing = _editing!.copyWith(exercises: exs));
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2A2A2E)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(s.addExerciseBtn,
                  style: const TextStyle(
                      color: kTextMuted, fontSize: 11, letterSpacing: 2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseEditRow extends StatelessWidget {
  final ExerciseTemplate ex;
  final ValueChanged<ExerciseTemplate> onChanged;
  final VoidCallback onDelete;

  const _ExerciseEditRow({
    super.key,
    required this.ex,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    final exercises = getExercises(s.languageCode);
    final wStr =
        ex.weight % 1 == 0 ? '${ex.weight.toInt()}' : '${ex.weight}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RawAutocomplete<String>(
                  initialValue: TextEditingValue(text: ex.name),
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) return const [];
                    final q = normalizeForSearch(v.text);
                    return exercises
                        .where((e) => normalizeForSearch(e).contains(q));
                  },
                  onSelected: (v) => onChanged(ex.copyWith(name: v)),
                  fieldViewBuilder: (ctx, ctrl, fn, _) => TextField(
                    controller: ctrl,
                    focusNode: fn,
                    style: const TextStyle(color: kText, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: s.exerciseNameHint,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onChanged: (v) => onChanged(ex.copyWith(name: v)),
                  ),
                  optionsViewBuilder: (ctx, onSel, opts) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: kSurface,
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxHeight: 200),
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
              IconButton(
                onPressed: onDelete,
                icon:
                    const Icon(Icons.close, color: kTextMuted, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PickerTile(
                label: s.setsLabel.toUpperCase(),
                value: '${ex.sets}',
                onTap: () async {
                  final v = await showSetsPicker(
                      context, ex.sets, s.selectSets, s.done);
                  if (!context.mounted) return;
                  if (v != null) onChanged(ex.copyWith(sets: v));
                },
              ),
              const SizedBox(width: 8),
              _PickerTile(
                label: s.weightLabel.toUpperCase(),
                value: wStr,
                onTap: () async {
                  final v = await showWeightPicker(
                      context, ex.weight, s.selectWeight, s.done);
                  if (!context.mounted) return;
                  if (v != null) onChanged(ex.copyWith(weight: v));
                },
              ),
              const SizedBox(width: 8),
              _PickerTile(
                label: s.repsLabel.toUpperCase(),
                value: '${ex.reps}',
                onTap: () async {
                  final v = await showRepsPicker(
                      context, ex.reps, s.selectReps, s.done);
                  if (!context.mounted) return;
                  if (v != null) onChanged(ex.copyWith(reps: v));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: kTextMuted, letterSpacing: 2)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderDim),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
