import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the master adaptiveMode flag — the INDEPENDENT VARIABLE of the study.
///
/// - false  -> MediAssist behaves exactly as the static control app.
/// - true   -> behaviour tracking + the adaptive UI engine become active
///             (added in later Phase 2 stages).
///
/// Researcher-controlled: the researcher sets the mode before handing the
/// device to a participant. Kept separate from SettingsProvider so adaptive
/// concerns stay isolated; in Stage 3 the engine will drive SettingsProvider.
class AdaptiveProvider extends ChangeNotifier {
  static const _kAdaptiveMode = 'adaptiveMode';

  bool _adaptiveMode = false;
  bool get adaptiveMode => _adaptiveMode;

  /// Load the saved mode at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _adaptiveMode = prefs.getBool(_kAdaptiveMode) ?? false;
    notifyListeners();
  }

  /// Set and persist the mode.
  Future<void> setAdaptiveMode(bool value) async {
    _adaptiveMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdaptiveMode, value);
  }
}
