import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The behaviour-tracking engine — the research core of MediAssist.
///
/// Records five interaction metrics PER SESSION, but ONLY when adaptive mode
/// is enabled (so the static control condition is never tracked):
///   M1 avg task-completion time   M2 error / mis-tap rate
///   M3 hesitation frequency       M4 retry taps        M5 screen revisits
///
/// Data is written to users/{uid}/behaviourSessions and later (Stage 4) used
/// to train the decision-tree classifier.
class BehaviourTracker {
  BehaviourTracker._();
  static final BehaviourTracker instance = BehaviourTracker._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// Turned on/off by AdaptiveProvider. Turning off clears the session so no
  /// data leaks into the static condition.
  void setEnabled(bool value) {
    _enabled = value;
    if (!value) _resetSession();
  }

  // ---- current session state ----
  String? _sessionId;
  DateTime? _sessionStart;
  int _totalActions = 0;
  int _errorCount = 0;
  int _hesitationCount = 0;
  int _retryTaps = 0;
  int _screenRevisits = 0;
  final List<double> _taskDurations = [];
  final Set<String> _visitedScreens = {};
  final Map<String, DateTime> _openTasks = {};
  DateTime? _lastEventTime;
  String? _lastEventLabel;

  static const _hesitationThreshold = Duration(seconds: 5);
  static const _retryWindow = Duration(milliseconds: 1500);

  void _ensureSession() {
    if (_sessionId != null) return;
    _sessionStart = DateTime.now();
    _sessionId = 'sess_${_sessionStart!.millisecondsSinceEpoch}';
  }

  void _resetSession() {
    _sessionId = null;
    _sessionStart = null;
    _totalActions = 0;
    _errorCount = 0;
    _hesitationCount = 0;
    _retryTaps = 0;
    _screenRevisits = 0;
    _taskDurations.clear();
    _visitedScreens.clear();
    _openTasks.clear();
    _lastEventTime = null;
    _lastEventLabel = null;
  }

  /// Shared logic: detects hesitation (long gap) and retries (same action fast).
  void _registerActivity(String label) {
    final now = DateTime.now();
    if (_lastEventTime != null) {
      final gap = now.difference(_lastEventTime!);
      if (gap >= _hesitationThreshold) _hesitationCount++;          // M3
      if (label == _lastEventLabel && gap <= _retryWindow) _retryTaps++; // M4
    }
    _lastEventTime = now;
    _lastEventLabel = label;
  }

  /// Every tap in the app (from the global listener in main.dart).
  void logTap(Offset position) {
    if (!_enabled) return;
    _ensureSession();
    _totalActions++; // M2 denominator
    // Coarse grid cell, so repeated taps in the same area register as retries.
    final label = 'tap_${position.dx ~/ 40}_${position.dy ~/ 40}';
    _registerActivity(label);
  }

  /// A user error: validation failure, invalid action, etc.
  void logError(String reason) {
    if (!_enabled) return;
    _ensureSession();
    _errorCount++; // M2 numerator
    _registerActivity('error_$reason');
  }

  /// Opening a screen — re-opening one counts as a revisit (M5).
  void logScreenOpen(String screen) {
    if (!_enabled) return;
    _ensureSession();
    if (_visitedScreens.contains(screen)) {
      _screenRevisits++;
    } else {
      _visitedScreens.add(screen);
    }
    _registerActivity('screen_$screen');
  }

  void startTask(String name) {
    if (!_enabled) return;
    _ensureSession();
    _openTasks[name] = DateTime.now();
  }

  Future<void> endTask(String name) async {
    if (!_enabled) return;
    final start = _openTasks.remove(name);
    if (start != null) {
      _taskDurations.add(DateTime.now().difference(start).inMilliseconds / 1000.0); // M1
    }
    await persist();
  }

  double get _avgTaskTime => _taskDurations.isEmpty
      ? 0
      : _taskDurations.reduce((a, b) => a + b) / _taskDurations.length;
  double get _errorRate => _totalActions == 0 ? 0 : _errorCount / _totalActions;

  /// Save/update the session summary in Firestore.
  Future<void> persist() async {
    if (!_enabled || _sessionId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users').doc(uid)
        .collection('behaviourSessions').doc(_sessionId)
        .set({
      'startedAt': Timestamp.fromDate(_sessionStart!),
      'updatedAt': FieldValue.serverTimestamp(),
      'adaptiveMode': true,
      'avgTaskTimeSec': double.parse(_avgTaskTime.toStringAsFixed(1)),
      'errorRate': double.parse(_errorRate.toStringAsFixed(3)),
      'hesitationCount': _hesitationCount,
      'retryTaps': _retryTaps,
      'screenRevisits': _screenRevisits,
      'totalActions': _totalActions,
      'errorCount': _errorCount,
    }, SetOptions(merge: true));
  }
}

/// Auto-logs screen opens (for revisit detection) from named routes.
class BehaviourNavigatorObserver extends NavigatorObserver {
  void _log(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) BehaviourTracker.instance.logScreenOpen(name);
  }
  @override
  void didPush(Route route, Route? previousRoute) => _log(route);
  @override
  void didPop(Route route, Route? previousRoute) => _log(previousRoute);
}
