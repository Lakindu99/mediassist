import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'behaviour_tracker.dart';
import 'adaptive_engine.dart';

class AdaptiveProvider extends ChangeNotifier {
  static const _kAdaptiveMode = 'adaptiveMode';
  final AdaptiveEngine engine;
  AdaptiveProvider({required this.engine});

  bool _adaptiveMode = false;
  bool get adaptiveMode => _adaptiveMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _adaptiveMode = prefs.getBool(_kAdaptiveMode) ?? false;
    _apply(_adaptiveMode);
    notifyListeners();
  }

  Future<void> setAdaptiveMode(bool value) async {
    _adaptiveMode = value;
    _apply(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdaptiveMode, value);
  }

  void _apply(bool v) {
    BehaviourTracker.instance.setEnabled(v);
    engine.setEnabled(v);
  }
}
