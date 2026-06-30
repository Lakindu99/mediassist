import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'behaviour_tracker.dart';

/// Holds the master adaptiveMode flag — the INDEPENDENT VARIABLE of the study.
/// Also enables/disables the BehaviourTracker so tracking only ever happens in
/// the adaptive condition.
class AdaptiveProvider extends ChangeNotifier {
  static const _kAdaptiveMode = 'adaptiveMode';

  bool _adaptiveMode = false;
  bool get adaptiveMode => _adaptiveMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _adaptiveMode = prefs.getBool(_kAdaptiveMode) ?? false;
    BehaviourTracker.instance.setEnabled(_adaptiveMode);
    notifyListeners();
  }

  Future<void> setAdaptiveMode(bool value) async {
    _adaptiveMode = value;
    BehaviourTracker.instance.setEnabled(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdaptiveMode, value);
  }
}
