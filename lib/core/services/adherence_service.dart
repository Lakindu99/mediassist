import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Records which medication doses have been taken, per user, per day.
/// Stored under users/{uid}/doseLogs. Each taken dose is one document whose
/// ID uniquely identifies (medication + date + time), so marking taken/undone
/// is simply creating or deleting that document.
class AdherenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('doseLogs');
  }

  /// A compact date stamp like "20260627".
  static String dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  /// Unique key for a single dose on a single day, e.g. "abc123_20260627_0800".
  static String doseKey(String medId, DateTime day, String time) =>
      '${medId}_${dateKey(day)}_${time.replaceAll(':', '')}';

  /// Live set of dose keys that have been marked taken today.
  Stream<Set<String>> watchTakenToday() {
    final key = dateKey(DateTime.now());
    return _ref.where('dateKey', isEqualTo: key).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Future<void> markTaken({
    required String medId,
    required String medName,
    required String time,
  }) async {
    final today = DateTime.now();
    await _ref.doc(doseKey(medId, today, time)).set({
      'medId': medId,
      'medName': medName,
      'time': time,
      'dateKey': dateKey(today),
      'takenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> undoTaken({required String medId, required String time}) async {
    final today = DateTime.now();
    await _ref.doc(doseKey(medId, today, time)).delete();
  }

  /// All taken-dose logs, newest first, for the history screen.
  Stream<List<Map<String, dynamic>>> watchAllLogs() {
    return _ref.orderBy('takenAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => d.data()).toList(),
        );
  }

  /// Count of doses taken in the last 7 days (including today).
  Stream<int> watchWeekCount() {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final cutoffKey = dateKey(sevenDaysAgo);
    return _ref.snapshots().map((snap) => snap.docs
        .where((d) => (d.data()['dateKey'] ?? '').compareTo(cutoffKey) >= 0)
        .length);
  }
}
