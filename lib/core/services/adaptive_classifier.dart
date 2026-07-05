import 'behaviour_tracker.dart';

/// MediAssist - Adaptive UI Classifier (auto-generated from a trained
/// scikit-learn Decision Tree; see ml/train_adaptive_model.py).
///
/// Classifies the user's interaction state from the five behavioural metrics
/// and returns an adaptation LEVEL (0 = none, 1 = mild, 2 = strong). Runs fully
/// on-device with no dependencies - a faithful port of the trained tree.
///
/// Classes: 0 = Confident, 1 = Moderate, 2 = NeedsSupport.
class AdaptiveClassifier {
  /// Predict adaptation level (0/1/2) from a behaviour snapshot.
  static int predict(BehaviourSnapshot f) {
    if (f.avgTaskTimeSec <= 19.4616) {
      if (f.avgTaskTimeSec <= 10.5153) {
        if (f.errorRate <= 0.1607) {
          if (f.errorRate <= 0.1279) {
            return 0;  // Confident
          } else {
            return 0;  // Confident
          }
        } else {
          return 1;  // Moderate
        }
      } else {
        if (f.hesitationCount <= 1.9063) {
          if (f.screenRevisits <= 2.0522) {
            return 0;  // Confident
          } else {
            return 1;  // Moderate
          }
        } else {
          if (f.errorRate <= 0.2816) {
            return 1;  // Moderate
          } else {
            return 1;  // Moderate
          }
        }
      }
    } else {
      if (f.errorRate <= 0.2383) {
        return 2;  // NeedsSupport
      } else {
        if (f.screenRevisits <= 3.7554) {
          return 2;  // NeedsSupport
        } else {
          return 2;  // NeedsSupport
        }
      }
    }
  }
}
