import 'package:flutter/material.dart';
import 'behaviour_tracker.dart';
import 'adaptive_classifier.dart';
import 'adaptation_log_service.dart';

enum AdaptiveStrategy { ruleBased, ml }

class AdaptiveEngine extends ChangeNotifier {
  bool _enabled = false;
  AdaptiveStrategy strategy = AdaptiveStrategy.ml;

  int activeLevel = 0;
  int ruleLevel = 0;
  int mlLevel = 0;

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
      _updateActive((strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel, 'Strategy change');
    }
    notifyListeners();
  }

  void evaluate(BehaviourSnapshot s) {
    _last = s;
    ruleLevel = _ruleBasedLevel(s);
    mlLevel = AdaptiveClassifier.predict(s);
    if (_enabled && _preview == null) {
      _updateActive((strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel, _reason(s));
    }
    BehaviourTracker.instance.recordDecision(ruleLevel, mlLevel, activeLevel, strategy.name);
    notifyListeners();
  }

  /// Change the active level and log the adaptation event (only on real change).
  void _updateActive(int newLevel, String reason) {
    if (newLevel == activeLevel) return;
    final from = activeLevel;
    activeLevel = newLevel;
    if (_enabled) {
      AdaptationLogService.instance.record(
        fromLevel: from,
        toLevel: newLevel,
        strategy: strategy.name,
        reason: reason,
        snapshot: _last,
      );
    }
  }

  /// Human-readable reason for the current adaptation (from the metrics).
  String _reason(BehaviourSnapshot s) {
    if (s.errorRate > 0.30 || s.retryTaps >= 3) return 'High errors / retry taps';
    if (s.avgTaskTimeSec > 20 || s.hesitationCount >= 5) return 'Slow tasks / hesitation';
    if (s.screenRevisits >= 4) return 'Frequent screen revisits';
    if (s.errorRate > 0.15) return 'Moderate error rate';
    if (s.avgTaskTimeSec > 12 || s.hesitationCount >= 3) return 'Moderate task time';
    if (s.screenRevisits >= 2) return 'Some screen revisits';
    return 'Low interaction load';
  }

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

  void setPreview(int? level) {
    _preview = level;
    if (level == null) {
      if (_enabled) activeLevel = (strategy == AdaptiveStrategy.ml) ? mlLevel : ruleLevel;
    } else {
      activeLevel = level;
    }
    notifyListeners();
  }

  bool get isPreviewing => _preview != null;

  double get fontScale => const [1.0, 1.15, 1.35][activeLevel];
  double get buttonScale => const [1.0, 1.15, 1.30][activeLevel];
  bool get forceHighContrast => activeLevel >= 2;
  bool get simplifyNav => activeLevel >= 2;

  /// A gentle explanation of the current adaptation, shown to the user.
  /// Null when there is nothing to explain (level 0 or disabled).
  String? get currentRecommendation {
    if (!_enabled || activeLevel == 0) return null;
    if (activeLevel >= 2) {
      return 'To make things easier, we have enlarged the text and buttons, '
          'increased contrast, and simplified this screen.';
    }
    return 'We have made the text and buttons a little larger to help you.';
  }
}
