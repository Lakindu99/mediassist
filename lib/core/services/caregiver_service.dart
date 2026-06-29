import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Links a caregiver to an elderly user. The elderly user generates a short
/// share code and gives it to their caregiver, who enters it to connect — so
/// the elderly user controls who can monitor them (consent by design).
class CaregiverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _myDoc =>
      _firestore.collection('users').doc(_auth.currentUser!.uid);

  /// ELDERLY: generate (or refresh) a 6-character share code and save it.
  Future<String> generateShareCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // excludes confusing 0/O/1/I
    final rng = Random.secure();
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    await _myDoc.update({'shareCode': code});
    return code;
  }

  /// ELDERLY: stream their current share code (null if none generated yet).
  Stream<String?> watchMyShareCode() =>
      _myDoc.snapshots().map((d) => d.data()?['shareCode'] as String?);

  /// CAREGIVER: link to an elderly user by their share code.
  /// Returns an error message, or null on success.
  Future<String?> linkByCode(String code) async {
    // Single-field query (no composite index needed); we verify the role after.
    final query = await _firestore
        .collection('users')
        .where('shareCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return 'No user found with that code. Please check and try again.';
    }
    final doc = query.docs.first;
    if ((doc.data()['role'] ?? '') != 'elderly') {
      return 'That code does not belong to an elderly user.';
    }
    await _myDoc.update({
      'linkedElderlyUid': doc.id,
      'linkedElderlyName': doc.data()['name'] ?? 'Elderly user',
    });
    return null;
  }

  /// CAREGIVER: stream the linked elderly user's {uid, name}, or null.
  Stream<Map<String, String>?> watchLinkedElderly() {
    return _myDoc.snapshots().map((d) {
      final data = d.data();
      final uid = data?['linkedElderlyUid'] as String?;
      if (uid == null) return null;
      return {'uid': uid, 'name': (data?['linkedElderlyName'] as String?) ?? 'Elderly user'};
    });
  }

  /// CAREGIVER: remove the link.
  Future<void> unlink() async {
    await _myDoc.update({
      'linkedElderlyUid': FieldValue.delete(),
      'linkedElderlyName': FieldValue.delete(),
    });
  }
}
