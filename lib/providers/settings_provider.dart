import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _weekStartMondayKey = 'week_start_monday';

  bool _weekStartsOnMonday = false;

  bool get weekStartsOnMonday => _weekStartsOnMonday;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _weekStartsOnMonday = prefs.getBool(_weekStartMondayKey) ?? false;
    notifyListeners();
  }

  Future<void> setWeekStartsOnMonday(bool value) async {
    _weekStartsOnMonday = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekStartMondayKey, value);
  }

  Future<void> toggleWeekStart() async {
    await setWeekStartsOnMonday(!_weekStartsOnMonday);
  }
}
