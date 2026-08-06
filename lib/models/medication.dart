import '../core/models/dose_slot.dart';

/// Represents a single medication belonging to a user.
///
/// - 'times' holds resolved times of day as "HH:mm" strings (e.g. "08:00").
///   This is the SOURCE OF TRUTH for reminders, the Today view and adherence,
///   and is kept unchanged for backward compatibility.
/// - 'schedule' (optional) holds the richer dose info (named meal slot + time)
///   used by the new flexible picker. Older medicines have no schedule and are
///   treated as custom times, so nothing breaks.
class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final List<DoseTime> schedule;
  final String notes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    this.schedule = const [],
    this.notes = '',
  });

  /// The editable fields, ready to save to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'times': times, // kept as the resolved-time source of truth
      'schedule': schedule.map((d) => d.toMap()).toList(),
      'notes': notes,
    };
  }

  /// Build a Medication from a Firestore document's id + data.
  factory Medication.fromMap(String id, Map<String, dynamic> data) {
    final times = List<String>.from(data['times'] ?? const []);

    // New medicines have a 'schedule'; older ones don't — rebuild it from the
    // plain times so the rest of the app can always rely on `schedule`.
    List<DoseTime> schedule;
    final rawSchedule = data['schedule'];
    if (rawSchedule is List && rawSchedule.isNotEmpty) {
      schedule = rawSchedule
          .map((e) => DoseTime.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      schedule = times.map((t) => DoseTime.fromLegacy(t)).toList();
    }

    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      times: times,
      schedule: schedule,
      notes: data['notes'] ?? '',
    );
  }
}
