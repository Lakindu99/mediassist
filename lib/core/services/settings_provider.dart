import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's accessibility preferences (text size + high contrast) and
/// saves them on the device. The whole app listens to this and rebuilds when it
/// changes — so settings apply instantly everywhere.
///
/// IMPORTANT (Phase 2 bridge): in the adaptive version, the Adaptive UI Engine
/// will call these same setters automatically based on the user's behaviour.
/// This class is the single point of control for UI adaptation.
class SettingsProvider extends ChangeNotifier {
  static const _kFontScale = 'fontScale';
  static const _kHighContrast = 'highContrast';
  static const _kReminderLeadMinutes = 'reminderLeadMinutes';

  double _fontScale = 1.0; // 1.0 = normal
  bool _highContrast = false;
  int _reminderLeadMinutes = 30; // how early "coming up" reminders fire

  double get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  int get reminderLeadMinutes => _reminderLeadMinutes;

  /// Load saved settings from the device. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_kFontScale) ?? 1.0;
    _highContrast = prefs.getBool(_kHighContrast) ?? false;
    _reminderLeadMinutes = prefs.getInt(_kReminderLeadMinutes) ?? 30;
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    notifyListeners(); // update the UI immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontScale, value); // then save
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, value);
  }

  Future<void> setReminderLeadMinutes(int value) async {
    _reminderLeadMinutes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderLeadMinutes, value);
  }
}
