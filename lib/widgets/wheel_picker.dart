import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<double?> showWeightPicker(
    BuildContext context, double initial, String title, String doneLabel) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _WeightPickerSheet(
        initial: initial, title: title, doneLabel: doneLabel),
  );
}

Future<int?> showRepsPicker(
    BuildContext context, int initial, String title, String doneLabel) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _IntPickerSheet(
        initial: initial, min: 1, max: 100, title: title, doneLabel: doneLabel),
  );
}

Future<int?> showSetsPicker(
    BuildContext context, int initial, String title, String doneLabel) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _IntPickerSheet(
        initial: initial, min: 1, max: 20, title: title, doneLabel: doneLabel),
  );
}

// ── 重量ピッカー（整数部 0-200 + 小数部 .0/.5 の2列）────────────────────────

class _WeightPickerSheet extends StatefulWidget {
  final double initial;
  final String title;
  final String doneLabel;
  const _WeightPickerSheet(
      {required this.initial, required this.title, required this.doneLabel});

  @override
  State<_WeightPickerSheet> createState() => _WeightPickerSheetState();
}

class _WeightPickerSheetState extends State<_WeightPickerSheet> {
  late int _int;
  late int _decIdx; // 0 → .0, 1 → .5
  late final FixedExtentScrollController _intCtrl;
  late final FixedExtentScrollController _decCtrl;

  @override
  void initState() {
    super.initState();
    _int = widget.initial.floor().clamp(0, 200);
    _decIdx = (widget.initial % 1.0 >= 0.25) ? 1 : 0;
    _intCtrl = FixedExtentScrollController(initialItem: _int);
    _decCtrl = FixedExtentScrollController(initialItem: _decIdx);
  }

  @override
  void dispose() {
    _intCtrl.dispose();
    _decCtrl.dispose();
    super.dispose();
  }

  double get _value => _int + (_decIdx == 1 ? 0.5 : 0.0);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Handle(),
      _Header(title: widget.title, doneLabel: widget.doneLabel,
          onDone: () => Navigator.pop(context, _value)),
      SizedBox(
        height: 200,
        child: Stack(alignment: Alignment.center, children: [
          _HighlightBand(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // 整数部
            SizedBox(
              width: 110,
              child: ListWheelScrollView(
                controller: _intCtrl,
                itemExtent: 44,
                diameterRatio: 2.0,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _int = i),
                children: List.generate(201,
                    (i) => _Item('$i')),
              ),
            ),
            const Text('.', style: TextStyle(color: kText, fontSize: 26, fontWeight: FontWeight.bold)),
            // 小数部
            SizedBox(
              width: 60,
              child: ListWheelScrollView(
                controller: _decCtrl,
                itemExtent: 44,
                diameterRatio: 2.0,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _decIdx = i),
                children: const [_Item('0'), _Item('5')],
              ),
            ),
            const SizedBox(width: 10),
            const Text('kg', style: TextStyle(color: kTextDim, fontSize: 16, letterSpacing: 2)),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

// ── 整数ピッカー（回数・セット数）────────────────────────────────────────────

class _IntPickerSheet extends StatefulWidget {
  final int initial;
  final int min;
  final int max;
  final String title;
  final String doneLabel;
  const _IntPickerSheet(
      {required this.initial,
      required this.min,
      required this.max,
      required this.title,
      required this.doneLabel});

  @override
  State<_IntPickerSheet> createState() => _IntPickerSheetState();
}

class _IntPickerSheetState extends State<_IntPickerSheet> {
  late int _selected;
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(widget.min, widget.max);
    _ctrl = FixedExtentScrollController(initialItem: _selected - widget.min);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Handle(),
      _Header(title: widget.title, doneLabel: widget.doneLabel,
          onDone: () => Navigator.pop(context, _selected)),
      SizedBox(
        height: 200,
        child: Stack(alignment: Alignment.center, children: [
          _HighlightBand(),
          SizedBox(
            width: 100,
            child: ListWheelScrollView(
              controller: _ctrl,
              itemExtent: 44,
              diameterRatio: 2.0,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) => setState(() => _selected = widget.min + i),
              children: List.generate(widget.max - widget.min + 1,
                  (i) => _Item('${widget.min + i}')),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

// ── 共通部品 ─────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: kBorderDim, borderRadius: BorderRadius.circular(2))),
      );
}

class _Header extends StatelessWidget {
  final String title;
  final String doneLabel;
  final VoidCallback onDone;
  const _Header(
      {required this.title, required this.doneLabel, required this.onDone});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
        child: Row(children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11, color: kTextMuted, letterSpacing: 3)),
          const Spacer(),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
            child: Text(doneLabel),
          ),
        ]),
      );
}

class _HighlightBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: kRed.withAlpha(20),
            border: const Border(
              top: BorderSide(color: kRed, width: 0.5),
              bottom: BorderSide(color: kRed, width: 0.5),
            ),
          ),
        ),
      );
}

class _Item extends StatelessWidget {
  final String text;
  const _Item(this.text);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(text,
            style: const TextStyle(color: kText, fontSize: 26, letterSpacing: 1)),
      );
}

/// ワークアウト画面などで値を表示してタップでピッカーを開くタイル
class WheelFieldTile extends StatelessWidget {
  final String value;
  final String unit;
  final VoidCallback onTap;

  const WheelFieldTile(
      {super.key,
      required this.value,
      required this.unit,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: kBg,
          border: Border.all(color: kBorderDim),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(value,
            style: const TextStyle(
                color: kText, fontSize: 15, letterSpacing: 1)),
      ),
    );
  }
}
