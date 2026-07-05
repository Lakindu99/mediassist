"""
MediAssist - Adaptive UI Decision-Tree Training Pipeline
=========================================================
Trains a lightweight Decision Tree that classifies an elderly user's
interaction state from five behavioural metrics, and maps that state to an
adaptation level. Also auto-generates the equivalent Dart classifier so the
model runs on-device with zero dependencies.

FIVE INPUT FEATURES (per session):
    avgTaskTimeSec, errorRate, hesitationCount, retryTaps, screenRevisits

THREE OUTPUT CLASSES (user state -> adaptation level):
    0 = Confident     -> Level 0 (no adaptation)
    1 = Moderate      -> Level 1 (mild adaptation)
    2 = NeedsSupport  -> Level 2 (strong adaptation)

NOTE ON DATA (state this in the thesis for academic honesty):
    This initial model is trained on a *principled bootstrap dataset* whose
    class distributions are grounded in Cognitive Load Theory and the project's
    rule thresholds, with deliberate overlap and noise so the learned boundaries
    are non-trivial. During evaluation, real participant sessions (exported from
    Firestore) replace this dataset and the model is RETRAINED with the same
    script - giving a fully reproducible pipeline.
"""

import numpy as np
from sklearn.tree import DecisionTreeClassifier, export_text, plot_tree, _tree
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, accuracy_score
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

RNG = np.random.default_rng(42)
FEATURES = ["avgTaskTimeSec", "errorRate", "hesitationCount", "retryTaps", "screenRevisits"]
CLASS_NAMES = ["Confident", "Moderate", "NeedsSupport"]

# ---------------------------------------------------------------------------
# 1. Generate a principled bootstrap dataset
# ---------------------------------------------------------------------------
def sample_class(label, n):
    """Draw n samples for a class from ranges grounded in the rule thresholds,
    with noise + overlap so the classes are not trivially separable."""
    if label == 0:      # Confident
        t   = RNG.normal(8,  2.5, n)
        err = RNG.normal(0.06, 0.05, n)
        hes = RNG.normal(1,  1.0, n)
        ret = RNG.normal(0.5, 0.7, n)
        rev = RNG.normal(1,  1.0, n)
    elif label == 1:    # Moderate
        t   = RNG.normal(15, 3.0, n)
        err = RNG.normal(0.20, 0.06, n)
        hes = RNG.normal(3.5, 1.3, n)
        ret = RNG.normal(2,  1.0, n)
        rev = RNG.normal(3,  1.2, n)
    else:               # NeedsSupport
        t   = RNG.normal(26, 5.0, n)
        err = RNG.normal(0.40, 0.10, n)
        hes = RNG.normal(7,  2.0, n)
        ret = RNG.normal(4.5, 1.6, n)
        rev = RNG.normal(6,  2.0, n)
    X = np.column_stack([t, err, hes, ret, rev])
    X = np.clip(X, 0, None)                       # no negative metrics
    X[:, 1] = np.clip(X[:, 1], 0, 1)              # error rate in [0,1]
    y = np.full(n, label)
    return X, y

parts = [sample_class(c, 300) for c in (0, 1, 2)]
X = np.vstack([p[0] for p in parts])
y = np.concatenate([p[1] for p in parts])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y)

# ---------------------------------------------------------------------------
# 2. Train a shallow, interpretable Decision Tree
# ---------------------------------------------------------------------------
clf = DecisionTreeClassifier(
    max_depth=4,            # shallow -> interpretable, avoids overfitting
    min_samples_leaf=20,    # each rule is supported by enough samples
    criterion="gini",
    random_state=42,
)
clf.fit(X_train, y_train)

# ---------------------------------------------------------------------------
# 3. Evaluate
# ---------------------------------------------------------------------------
test_acc = accuracy_score(y_test, clf.predict(X_test))
cv = cross_val_score(clf, X, y, cv=5)
print("=" * 60)
print("MediAssist Adaptive Decision Tree - training results")
print("=" * 60)
print(f"Test accuracy      : {test_acc:.3f}")
print(f"5-fold CV accuracy : {cv.mean():.3f} (+/- {cv.std():.3f})")
print("\nClassification report (test set):")
print(classification_report(y_test, clf.predict(X_test), target_names=CLASS_NAMES))
print("Feature importances:")
for f, imp in sorted(zip(FEATURES, clf.feature_importances_), key=lambda z: -z[1]):
    print(f"  {f:<18} {imp:.3f}")
print("\nLearned rules:")
print(export_text(clf, feature_names=FEATURES))

# ---------------------------------------------------------------------------
# 4. Export a tree diagram for the thesis
# ---------------------------------------------------------------------------
plt.figure(figsize=(20, 10))
plot_tree(clf, feature_names=FEATURES, class_names=CLASS_NAMES,
          filled=True, rounded=True, fontsize=9, impurity=False)
plt.title("MediAssist - Adaptive UI Decision Tree", fontsize=16)
plt.tight_layout()
plt.savefig("/mnt/user-data/outputs/adaptive_decision_tree.png", dpi=130, bbox_inches="tight")
print("\nSaved tree diagram -> adaptive_decision_tree.png")

# ---------------------------------------------------------------------------
# 5. Auto-generate the equivalent Dart classifier from the trained tree
# ---------------------------------------------------------------------------
def tree_to_dart(clf):
    t = clf.tree_
    fnames = [FEATURES[i] if i != _tree.TREE_UNDEFINED else "undef" for i in t.feature]
    lines = []

    def recurse(node, depth):
        pad = "  " * (depth + 2)
        if t.feature[node] != _tree.TREE_UNDEFINED:
            name = fnames[node]
            thr = t.threshold[node]
            lines.append(f"{pad}if (f.{name} <= {thr:.4f}) {{")
            recurse(t.children_left[node], depth + 1)
            lines.append(f"{pad}}} else {{")
            recurse(t.children_right[node], depth + 1)
            lines.append(f"{pad}}}")
        else:
            cls = int(np.argmax(t.value[node][0]))
            lines.append(f"{pad}return {cls};  // {CLASS_NAMES[cls]}")

    recurse(0, 0)
    return "\n".join(lines)

dart_body = tree_to_dart(clf)
dart_file = '''import 'behaviour_tracker.dart';

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
%s
  }
}
''' % dart_body

with open("/mnt/user-data/outputs/adaptive_classifier.dart", "w") as fh:
    fh.write(dart_file)
print("Generated Dart classifier -> adaptive_classifier.dart")
print("\nDart classifier preview:\n")
print(dart_file)
