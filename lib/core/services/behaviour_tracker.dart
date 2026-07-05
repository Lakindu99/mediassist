import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A read-only snapshot of the current session's five metrics.
class BehaviourSnapshot {
  final double avgTaskTimeSec;
  final double errorRate;
  final int hesitationCount;
  final int retryTaps;
  final int screenRevisits;
  const BehaviourSnapshot({
    required this.avgTaskTimeSec,
    required this.errorRate,
    required this.hesitationCount,
    required this.retryTaps,
    required this.screenRevisits,
  });
  static const BehaviourSnapshot zero =
      BehaviourSnapshot(avgTaskTimeSec: 0, errorRate: 0, hesitationCount: 0, retryTaps: 0, screenRevisits: 0);
}

/// The behaviour-tracking engine. Records five metrics per session, but ONLY
/// when adaptive mode is enabled. Notifies a listener (the AdaptiveEngine)
/// whenever metrics change.
class BehaviourTracker {
  BehaviourTracker._();
  static final BehaviourTracker instance = BehaviourTracker._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Set by main.dart to the AdaptiveEngine's evaluate method.
  void Function(BehaviourSnapshot)? onMetricsChanged;

  bool _enabled = false;
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) _resetSession();
  }

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

  void _registerActivity(String label) {
    final now = DateTime.now();
    if (_lastEventTime != null) {
      final gap = now.difference(_lastEventTime!);
      if (gap >= _hesitationThreshold) _hesitationCount++;
      if (label == _lastEventLabel && gap <= _retryWindow) _retryTaps++;
    }
    _lastEventTime = now;
    _lastEventLabel = label;
  }

  double get _avgTaskTime => _taskDurations.isEmpty
      ? 0
      : _taskDurations.reduce((a, b) => a + b) / _taskDurations.length;
  double get _errorRate => _totalActions == 0 ? 0 : _errorCount / _totalActions;

  /// Current metrics as a snapshot (fed to the AdaptiveEngine).
  BehaviourSnapshot get snapshot => BehaviourSnapshot(
        avgTaskTimeSec: double.parse(_avgTaskTime.toStringAsFixed(1)),
        errorRate: double.parse(_errorRate.toStringAsFixed(3)),
        hesitationCount: _hesitationCount,
        retryTaps: _retryTaps,
        screenRevisits: _screenRevisits,
      );

  void _notify() {
    if (_enabled) onMetricsChanged?.call(snapshot);
  }

  void logTap(Offset position) {
    if (!_enabled) return;
    _ensureSession();
    _totalActions++;
    _registerActivity('tap_${position.dx ~/ 40}_${position.dy ~/ 40}');
    _notify();
  }

  void logError(String reason) {
    if (!_enabled) return;
    _ensureSession();
    _errorCount++;
    _registerActivity('error_$reason');
    _notify();
  }

  void logScreenOpen(String screen) {
    if (!_enabled) return;
    _ensureSession();
    if (_visitedScreens.contains(screen)) {
      _screenRevisits++;
    } else {
      _visitedScreens.add(screen);
    }
    _registerActivity('screen_$screen');
    _notify();
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
      _taskDurations.add(DateTime.now().difference(start).inMilliseconds / 1000.0);
    }
    _notify();
    await persist();
  }

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
