import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  bool _isHindi = false;

  bool get isHindi => _isHindi;

  LocaleProvider() {
    _loadFromPrefs();
  }

  void toggleLanguage(bool val) {
    _isHindi = val;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isHindi = prefs.getBool('isHindi') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHindi', _isHindi);
  }
}
