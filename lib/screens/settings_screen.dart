import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _fs = FirestoreService();

  AppStrings get _s => context.read<LocaleProvider>().s;

  Future<void> _linkWithGoogle() async {
    final s = _s;
    try {
      final result = await _auth.linkWithGoogle();
      if (result == null) return; // ユーザーがキャンセル
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.linkedGoogle), backgroundColor: kRed));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${s.linkGoogle}: $e'), backgroundColor: kRed));
      }
    }
  }

  Future<void> _confirmGuestLogout() async {
    final s = _s;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.logout, style: const TextStyle(color: kText)),
        content: Text(s.logoutGuestBody,
            style: const TextStyle(
                color: kTextDim, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.logout),
          ),
        ],
      ),
    );
    if (confirm == true) await _auth.signOut();
  }

  void _confirmDelete() {
    final s = _s;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(s.deleteAccountTitle,
            style: const TextStyle(color: kText)),
        content: Text(s.deleteAccountBody,
            style: const TextStyle(
                color: kTextDim, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final s = _s;
    try {
      await _fs.deleteAllUserData();
      await _auth.deleteAccount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.deleteFailed),
            backgroundColor: kRed,
            duration: const Duration(seconds: 4)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final s = lp.s;
    final user = FirebaseAuth.instance.currentUser;
    final isAnon = user?.isAnonymous ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.tabSettings.toUpperCase(),
            style: const TextStyle(
                fontSize: 10, color: kTextMuted, letterSpacing: 3)),
        const SizedBox(height: 20),
        Text(s.language.toUpperCase(),
            style: const TextStyle(
                fontSize: 9, color: kTextMuted, letterSpacing: 3)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kSurface,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(children: [
            _LangTile(label: s.japanese, code: 'ja', lp: lp),
            const Divider(color: kBorder, height: 1),
            _LangTile(label: s.english, code: 'en', lp: lp),
          ]),
        ),
        const SizedBox(height: 24),
        Text(s.account.toUpperCase(),
            style: const TextStyle(
                fontSize: 9, color: kTextMuted, letterSpacing: 3)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kSurface,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(children: [
            if (isAnon) ...[
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: const Icon(Icons.link, color: kText, size: 20),
                title: Text(s.linkGoogle,
                    style: const TextStyle(
                        color: kText, fontSize: 14, letterSpacing: 1)),
                subtitle: Text(s.linkGoogleSub,
                    style:
                        const TextStyle(color: kTextMuted, fontSize: 11)),
                onTap: _linkWithGoogle,
              ),
              const Divider(color: kBorder, height: 1),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: const Icon(Icons.logout, color: kTextDim, size: 20),
                title: Text(s.logout,
                    style: const TextStyle(
                        color: kTextDim, fontSize: 14, letterSpacing: 1)),
                subtitle: Text(s.logoutGuestSub,
                    style:
                        const TextStyle(color: kTextMuted, fontSize: 11)),
                onTap: _confirmGuestLogout,
              ),
            ] else
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: const Icon(Icons.logout, color: kText, size: 20),
                title: Text(s.logout,
                    style: const TextStyle(
                        color: kText, fontSize: 14, letterSpacing: 1)),
                onTap: () => _auth.signOut(),
              ),
            const Divider(color: kBorder, height: 1),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading:
                  const Icon(Icons.delete_forever, color: kRed, size: 20),
              title: Text(s.deleteAccount,
                  style: const TextStyle(
                      color: kRed, fontSize: 14, letterSpacing: 1)),
              subtitle: Text(s.deleteAccountSub,
                  style:
                      const TextStyle(color: kTextMuted, fontSize: 11)),
              onTap: _confirmDelete,
            ),
          ]),
        ),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String code;
  final LocaleProvider lp;

  const _LangTile(
      {required this.label, required this.code, required this.lp});

  @override
  Widget build(BuildContext context) {
    final selected = lp.locale.languageCode == code;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(label,
          style: TextStyle(
              color: selected ? kRed : kText,
              fontSize: 14,
              letterSpacing: 1)),
      trailing: selected
          ? const Icon(Icons.check, color: kRed, size: 18)
          : null,
      onTap: () => lp.setLocale(code),
    );
  }
}
