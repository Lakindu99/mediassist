/// Represents a single medication belonging to a user.
/// 'times' holds times of day as "HH:mm" strings (e.g. "08:00") — the
/// reminder system will later use these to schedule notifications.
class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final String notes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    this.notes = '',
  });

  /// The editable fields, ready to save to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'times': times,
      'notes': notes,
    };
  }

  /// Build a Medication from a Firestore document's id + data.
  factory Medication.fromMap(String id, Map<String, dynamic> data) {
    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      times: List<String>.from(data['times'] ?? const []),
      notes: data['notes'] ?? '',
    );
  }
}
