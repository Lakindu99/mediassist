import 'package:flutter/material.dart';
import 'behaviour_tracker.dart';
import 'adaptive_classifier.dart';

/// Which decision source drives the adaptive UI.
enum AdaptiveStrategy { ruleBased, ml }

/// The Adaptive UI Engine (Phase 2, Stages 3-4).
///
/// Computes an adaptation LEVEL (0 none, 1 mild, 2 strong) from the live
/// behaviour snapshot using BOTH a transparent rule set and the trained
/// decision-tree classifier. One strategy drives the UI (researcher-selectable);
/// both decisions are always recorded so rule-based vs ML can be compared.
class AdaptiveEngine extends ChangeNotifier {
  bool _enabled = false;

  /// ML is the research contribution (default); the researcher can switch to
  /// rule-based for comparison.
  AdaptiveStrategy strategy = AdaptiveStrategy.ml;

  int activeLevel = 0; // level currently driving the UI
  int ruleLevel = 0;   // the rule-based decision
  int mlLevel = 0;     // the decision-tree decision

  int? _preview;
  BehaviourSnapshot _last = BehaviourSnapshot.zero;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      _preview = null;
      activeLevel = 0;
      ruleLevel = 0;
      mlLevel = 0;
      notifyListeners();
    }
  }

  void setStrategy(AdaptiveStrategy s) {
    strategy = s;
    if (_enabled && _preview == null) {
      activeLevel = (strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel;
    }
    notifyListeners();
  }

  /// Called whenever behaviour metrics change (wired from BehaviourTracker).
  void evaluate(BehaviourSnapshot s) {
    _last = s;
    // Always compute BOTH decisions, for the rule-vs-ML comparison.
    ruleLevel = _ruleBasedLevel(s);
    mlLevel = AdaptiveClassifier.predict(s);
    if (_enabled && _preview == null) {
      activeLevel = (strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel;
    }
    // Record the comparison so it is saved with the session.
    BehaviourTracker.instance
        .recordDecision(ruleLevel, mlLevel, activeLevel, strategy.name);
    notifyListeners();
  }

  /// Transparent rule set: reduces the five metrics to a 0/1/2 level.
  int _ruleBasedLevel(BehaviourSnapshot s) {
    final strong = s.errorRate > 0.30 ||
        s.retryTaps >= 3 ||
        s.avgTaskTimeSec > 20 ||
        s.hesitationCount >= 5 ||
        s.screenRevisits >= 4;
    final mild = s.errorRate > 0.15 ||
        s.avgTaskTimeSec > 12 ||
        s.hesitationCount >= 3 ||
        s.screenRevisits >= 2;
    if (strong) return 2;
    if (mild) return 1;
    return 0;
  }

  /// Demo/testing: force a level. null returns to live behaviour-driven rules.
  void setPreview(int? level) {
    _preview = level;
    if (level == null) {
      if (_enabled) {
        activeLevel = (strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel;
      }
    } else {
      activeLevel = level;
    }
    notifyListeners();
  }

  bool get isPreviewing => _preview != null;

  // Active level -> concrete UI settings.
  double get fontScale => const [1.0, 1.15, 1.35][activeLevel];
  double get buttonScale => const [1.0, 1.15, 1.30][activeLevel];
  bool get forceHighContrast => activeLevel >= 2;
  bool get simplifyNav => activeLevel >= 2;
}
