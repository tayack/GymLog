import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _fs = FirestoreService();
  int _page = 0;

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
                            fontSize: 10, color: kTextMuted, letterSpacing: 1)),
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
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kSurface),
                    dataRowColor: WidgetStateProperty.resolveWith(
                        (st) => st.contains(WidgetState.selected) ? kSurface : kBg),
                    border: TableBorder.all(color: kBorder, width: 1),
                    columnSpacing: 12,
                    headingTextStyle: const TextStyle(
                        fontSize: 9, color: kTextMuted, letterSpacing: 2),
                    dataTextStyle: const TextStyle(fontSize: 10, color: kText),
                    columns: [
                      DataColumn(label: Text(s.exerciseCol)),
                      ...pageData.map((w) => DataColumn(
                            label: Text(
                              DateFormat('MM/dd(E)', s.languageCode).format(w.date),
                              style:
                                  const TextStyle(fontSize: 10, color: kTextDim),
                            ),
                          )),
                    ],
                    rows: exList.map((ex) {
                      return DataRow(cells: [
                        DataCell(Text(ex,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA)))),
                        ...pageData.map((w) {
                          final exData =
                              w.sets.where((es) => es.exercise == ex).firstOrNull;
                          return DataCell(
                            exData == null
                                ? const Text('—',
                                    style: TextStyle(color: Color(0xFF2A2A2E)))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: exData.entries
                                        .map((e) => Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('${e.weight}',
                                                    style: const TextStyle(
                                                        color: kRed,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('×${e.reps}',
                                                    style: const TextStyle(
                                                        color: kTextMuted,
                                                        fontSize: 9)),
                                              ],
                                            ))
                                        .toList(),
                                  ),
                          );
                        }),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn({required this.icon, required this.enabled, required this.onTap});

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
        child: Icon(icon, size: 16, color: enabled ? kTextDim : kTextMuted),
      ),
    );
  }
}
