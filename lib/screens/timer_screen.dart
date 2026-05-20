import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  static const _presets = [30, 60, 90, 120, 180];
  int _totalSec = 90;
  int _left = 90;
  bool _running = false;
  bool _done = false;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  final _notif = FlutterLocalNotificationsPlugin();

  String _notifBody = 'インターバル終了！次のセットへ';
  String _notifChannelName = 'タイマー通知';
  String _notifChannelDesc = 'インターバルタイマー終了通知';

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
          ..repeat(reverse: true);
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notif.initialize(const InitializationSettings(android: android, iOS: ios));
    _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final s = context.read<LocaleProvider>().s;
    _notifBody = s.notifTimerBody;
    _notifChannelName = s.notifChannelName;
    _notifChannelDesc = s.notifChannelDesc;
    setState(() {
      _done = false;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        setState(() {
          _left = 0;
          _running = false;
          _done = true;
        });
        _timer?.cancel();
        _onComplete();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset([int? sec]) {
    _timer?.cancel();
    final s = sec ?? _totalSec;
    setState(() {
      if (sec != null) _totalSec = s;
      _left = s;
      _running = false;
      _done = false;
    });
  }

  Future<void> _onComplete() async {
    final hasVib = await Vibration.hasVibrator();
    if (hasVib == true) {
      Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 800]);
    }
    await _notif.show(
      0,
      'GymLog',
      _notifBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel',
          _notifChannelName,
          channelDescription: _notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    final progress = _totalSec > 0 ? (_totalSec - _left) / _totalSec : 0.0;
    final isWarning = _left <= 10 && _left > 0 && _running;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.intervalTimer,
                  style: const TextStyle(
                      fontSize: 10, color: kTextMuted, letterSpacing: 3)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _presets
                  .map((sec) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _PresetButton(
                          label: sec < 60 ? '${sec}s' : '${sec ~/ 60}m',
                          selected: _totalSec == sec,
                          onTap: () => _reset(sec),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _CirclePainter(
                        progress: progress, isWarning: isWarning, done: _done),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) => Opacity(
                          opacity: isWarning ? 0.4 + 0.6 * _pulseCtrl.value : 1.0,
                          child: child,
                        ),
                        child: Text(
                          _fmt(_left),
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: _done
                                ? kRed
                                : isWarning
                                    ? const Color(0xFFFF8C00)
                                    : kText,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _done ? s.complete : _running ? s.resting : s.ready,
                        style: const TextStyle(
                            fontSize: 9, color: kTextMuted, letterSpacing: 3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _running ? _pause : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _running ? const Color(0xFF252528) : kRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                  ),
                  child: Text(
                    _running ? '⏸ PAUSE' : '▶ START',
                    style: const TextStyle(fontSize: 13, letterSpacing: 3),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _reset(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextDim,
                    side: const BorderSide(color: kBorderDim),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  child: const Text('↺', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.timerNote,
                style: const TextStyle(
                    fontSize: 10, color: kTextMuted, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final bool isWarning;
  final bool done;

  _CirclePainter({required this.progress, required this.isWarning, required this.done});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = isWarning ? const Color(0xFFFF8C00) : kRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.progress != progress || old.isWarning != isWarning || old.done != done;
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kRed : kSurface,
          border: Border.all(color: selected ? kRed : kBorderDim),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: selected ? Colors.white : kTextDim,
            )),
      ),
    );
  }
}
