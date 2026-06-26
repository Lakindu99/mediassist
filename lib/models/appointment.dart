import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single medical appointment belonging to a user.
/// Unlike medication (which repeats daily), an appointment is a one-off
/// event, so it stores a single date+time as a Firestore Timestamp.
class Appointment {
  final String id;
  final String doctor;
  final DateTime dateTime;
  final String location;
  final String notes;

  Appointment({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.location,
    this.notes = '',
  });

  /// The editable fields, ready to save to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'doctor': doctor,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'notes': notes,
    };
  }

  /// Build an Appointment from a Firestore document's id + data.
  factory Appointment.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['dateTime'];
    return Appointment(
      id: id,
      doctor: data['doctor'] ?? '',
      dateTime: ts is Timestamp ? ts.toDate() : DateTime.now(),
      location: data['location'] ?? '',
      notes: data['notes'] ?? '',
    );
  }
}
