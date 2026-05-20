import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/locale_provider.dart';
import 'screens/workout_screen.dart';
import 'screens/history_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/banner_ad_widget.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();

  final localeProvider = LocaleProvider();
  await localeProvider.load();

  FlutterNativeSplash.remove();

  runApp(
    ChangeNotifierProvider.value(
      value: localeProvider,
      child: const GymLogApp(),
    ),
  );
}

class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      title: 'GymLog',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ja'), Locale('en')],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authState,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: kRed)));
        }
        if (snap.data == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}

// ── ログイン画面 ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  bool _loadingGoogle = false;
  bool _loadingAnon = false;

  Future<void> _signInGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showError('${context.read<LocaleProvider>().s.loginGoogle}: $e');
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _signInAnon() async {
    setState(() => _loadingAnon = true);
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loadingAnon = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kRed));
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final s = lp.s;
    final loading = _loadingGoogle || _loadingAnon;
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('GYMLOG',
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: kRed,
                          letterSpacing: 8)),
                  const SizedBox(height: 4),
                  const Text('筋トレ記録アプリ',
                      style: TextStyle(
                          fontSize: 12, color: kTextDim, letterSpacing: 3)),
                  const SizedBox(height: 48),
                  if (loading)
                    const CircularProgressIndicator(color: kRed)
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInGoogle,
                        icon: const Icon(Icons.login, size: 18),
                        label: Text(s.loginGoogle,
                            style: const TextStyle(
                                fontSize: 14, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _signInAnon,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: kTextDim,
                            side: const BorderSide(color: kBorderDim),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        child: Text(s.loginGuest,
                            style: const TextStyle(
                                fontSize: 14, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(s.loginGuestNote,
                        style: const TextStyle(
                            fontSize: 10,
                            color: kTextMuted,
                            letterSpacing: 1),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
          // 言語切替ボタン（右上）
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LangBtn(label: '日', code: 'ja'),
                    const SizedBox(width: 4),
                    _LangBtn(label: 'EN', code: 'en'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ホーム画面 ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final s = lp.s;
    final user = FirebaseAuth.instance.currentUser;
    final isAnon = user?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GYMLOG'),
        actions: [
          if (!isAnon && user?.photoURL != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(user!.photoURL!)),
            ),
          if (isAnon)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    border: Border.all(color: kBorderDim),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(s.guestBadge,
                    style: const TextStyle(
                        fontSize: 9, color: kTextMuted, letterSpacing: 2)),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              WorkoutScreen(onTabChange: (t) => setState(() => _tab = t)),
              const HistoryScreen(),
              const MenuScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
        const ColoredBox(
            color: kBg, child: Center(child: BannerAdWidget())),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.fitness_center), label: s.tabToday),
          BottomNavigationBarItem(
              icon: const Icon(Icons.history), label: s.tabHistory),
          BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book), label: s.tabRoutines),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings), label: s.tabSettings),
        ],
      ),
    );
  }
}

// ── 言語選択 ──────────────────────────────────────────────────────────────────

/// ログイン画面の言語切替ボタン（日 / EN）
class _LangBtn extends StatelessWidget {
  final String label;
  final String code;
  const _LangBtn({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final selected = lp.locale.languageCode == code;
    return GestureDetector(
      onTap: () => lp.setLocale(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kRed : Colors.transparent,
          border: Border.all(color: selected ? kRed : kBorderDim),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white : kTextMuted,
                letterSpacing: 1.5)),
      ),
    );
  }
}

