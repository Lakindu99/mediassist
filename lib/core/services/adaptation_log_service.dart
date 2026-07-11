import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'behaviour_tracker.dart';

/// Records every adaptation event (a change in adaptation level) with its
/// reason, strategy and the behaviour snapshot that triggered it. Provides the
/// evidence trail shown in the Adaptation Log screen and used in the thesis.
class AdaptationLogService {
  AdaptationLogService._();
  static final AdaptationLogService instance = AdaptationLogService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> record({
    required int fromLevel,
    required int toLevel,
    required String strategy,
    required String reason,
    required BehaviourSnapshot snapshot,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('adaptationLog').add({
      'timestamp': FieldValue.serverTimestamp(),
      'fromLevel': fromLevel,
      'toLevel': toLevel,
      'strategy': strategy,
      'reason': reason,
      'avgTaskTimeSec': snapshot.avgTaskTimeSec,
      'errorRate': snapshot.errorRate,
      'hesitationCount': snapshot.hesitationCount,
      'retryTaps': snapshot.retryTaps,
      'screenRevisits': snapshot.screenRevisits,
    });
  }

  Stream<List<Map<String, dynamic>>> watchLog() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users').doc(uid).collection('adaptationLog')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}
