import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ja');

  Locale get locale => _locale;
  AppStrings get s => AppStrings(_locale.languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'ja';
    _locale = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
  }
}
