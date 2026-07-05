import 'package:flutter/material.dart';
import 'behaviour_tracker.dart';

/// The rule-based Adaptive UI Engine (Phase 2, Stage 3).
///
/// Reads the live behaviour snapshot and applies transparent if-then rules to
/// decide how much to adapt the interface. Outputs graded LEVELS (0/1/2) that
/// the app maps to font size, button size, contrast and navigation. Every
/// decision is explainable — a research virtue we contrast with ML in Stage 4.
class AdaptiveEngine extends ChangeNotifier {
  bool _enabled = false;

  int fontLevel = 0;        // 0 none, 1 mild, 2 strong  (comprehension)
  int buttonLevel = 0;      // 0 none, 1 mild, 2 strong  (motor/targeting)
  bool forceHighContrast = false;
  bool simplifyNav = false;

  int? _preview;                          // demo override (null = auto)
  BehaviourSnapshot _last = BehaviourSnapshot.zero;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      _preview = null;
      _set(0, 0, false, false);
    }
  }

  /// Called whenever behaviour metrics change (wired from BehaviourTracker).
  void evaluate(BehaviourSnapshot s) {
    _last = s;
    if (!_enabled || _preview != null) return; // preview overrides live rules
    _applyRules(s);
  }

  /// The transparent rule set (from the Phase 2 Technical Design, Section 7).
  void _applyRules(BehaviourSnapshot s) {
    int font = 0;
    if (s.avgTaskTimeSec > 20 || s.hesitationCount >= 5) {
      font = 2;
    } else if (s.avgTaskTimeSec > 12) {
      font = 1;
    }

    int button = 0;
    if (s.errorRate > 0.30 || s.retryTaps >= 3) {
      button = 2;
    } else if (s.errorRate > 0.15) {
      button = 1;
    }

    final contrast = font >= 2;                // strong comprehension load
    final simplify = s.screenRevisits >= 4;    // navigation difficulty

    _set(font, button, contrast, simplify);
  }

  /// Demo/testing control (used in the Researcher Panel): force a level so you
  /// can show each adaptation instantly. null = return to live rules.
  void setPreview(int? level) {
    _preview = level;
    if (level == null) {
      _applyRules(_last);
    } else {
      _set(level, level, level >= 2, level >= 2);
    }
  }

  void _set(int font, int button, bool contrast, bool simplify) {
    if (font == fontLevel &&
        button == buttonLevel &&
        contrast == forceHighContrast &&
        simplify == simplifyNav) return;
    fontLevel = font;
    buttonLevel = button;
    forceHighContrast = contrast;
    simplifyNav = simplify;
    notifyListeners();
  }

  // Level → concrete scale factors.
  double get fontScale => const [1.0, 1.15, 1.35][fontLevel];
  double get buttonScale => const [1.0, 1.15, 1.30][buttonLevel];
}
