import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/appointment.dart';

/// All appointment database logic in one place. Stores each user's
/// appointments under users/{uid}/appointments, ordered by date/time.
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('appointments');
  }

  /// Live stream of the user's appointments, soonest first.
  Stream<List<Appointment>> watchAppointments() {
    return _ref.orderBy('dateTime').snapshots().map(
          (snap) => snap.docs.map((d) => Appointment.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addAppointment(Appointment appt) async {
    await _ref.add({
      ...appt.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppointment(Appointment appt) async {
    await _ref.doc(appt.id).update(appt.toMap());
  }

  Future<void> deleteAppointment(String id) async {
    await _ref.doc(id).delete();
  }
}
