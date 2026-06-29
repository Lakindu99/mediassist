import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medication.dart';

/// All medication database logic in one place. Screens call this service —
/// they never touch Firestore directly. Stores each user's medications under
/// users/{uid}/medications so data is naturally scoped per user.
class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _medsRef {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('medications');
  }

  /// Live stream of the user's medications, ordered by name.
  /// The UI updates automatically whenever data changes.
  Stream<List<Medication>> watchMedications() {
    return _medsRef.orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Medication.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Live stream of a SPECIFIC user's medications (used by caregivers).
  Stream<List<Medication>> watchMedicationsFor(String uid) {
    return _firestore
        .collection('users').doc(uid).collection('medications')
        .orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Medication.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addMedication(Medication med) async {
    await _medsRef.add({
      ...med.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMedication(Medication med) async {
    await _medsRef.doc(med.id).update(med.toMap());
  }

  Future<void> deleteMedication(String id) async {
    await _medsRef.doc(id).delete();
  }
}
