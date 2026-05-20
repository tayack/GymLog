import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ja');
  int _intervalDefault = 90;

  Locale get locale => _locale;
  AppStrings get s => AppStrings(_locale.languageCode);
  int get intervalDefault => _intervalDefault;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'ja';
    _locale = Locale(code);
    _intervalDefault = prefs.getInt('interval_default') ?? 90;
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
  }

  Future<void> setIntervalDefault(int secs) async {
    _intervalDefault = secs;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval_default', secs);
  }
}
