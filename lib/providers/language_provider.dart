import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isHindi => _locale.languageCode == 'hi';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setEnglish() async {
    _locale = const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', 'en');
    notifyListeners();
  }

  Future<void> setHindi() async {
    _locale = const Locale('hi');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', 'hi');
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (isHindi) {
      await setEnglish();
    } else {
      await setHindi();
    }
  }
}