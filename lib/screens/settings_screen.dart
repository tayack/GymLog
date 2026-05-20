import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    final lp = context.watch<LocaleProvider>();
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
          child: Column(
            children: [
              _LangTile(
                label: s.japanese,
                code: 'ja',
                lp: lp,
              ),
              const Divider(color: kBorder, height: 1),
              _LangTile(
                label: s.english,
                code: 'en',
                lp: lp,
              ),
            ],
          ),
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
