/// Defines how a medication dose time is chosen. MediAssist supports both
/// meal-relative "named slots" (friendlier for elderly users, who think in
/// terms of meals rather than clock times) and exact custom times.
///
/// Every slot still resolves to a real clock time, so the Today view,
/// reminders and adherence logging continue to work on concrete times — the
/// slots are only a friendlier way to CHOOSE the time.
enum DoseSlot {
  beforeBreakfast,
  afterBreakfast,
  beforeLunch,
  afterLunch,
  beforeDinner,
  afterDinner,
  bedtime,
  custom,
}

extension DoseSlotInfo on DoseSlot {
  /// Human-friendly label shown in the UI.
  String get label {
    switch (this) {
      case DoseSlot.beforeBreakfast:
        return 'Before Breakfast';
      case DoseSlot.afterBreakfast:
        return 'After Breakfast';
      case DoseSlot.beforeLunch:
        return 'Before Lunch';
      case DoseSlot.afterLunch:
        return 'After Lunch';
      case DoseSlot.beforeDinner:
        return 'Before Dinner';
      case DoseSlot.afterDinner:
        return 'After Dinner';
      case DoseSlot.bedtime:
        return 'Bedtime';
      case DoseSlot.custom:
        return 'Custom Time';
    }
  }

  /// The default clock time (HH:mm) each named slot maps to. These are sensible
  /// defaults for a typical day; a custom slot has no default.
  String? get defaultTime {
    switch (this) {
      case DoseSlot.beforeBreakfast:
        return '07:00';
      case DoseSlot.afterBreakfast:
        return '08:00';
      case DoseSlot.beforeLunch:
        return '12:00';
      case DoseSlot.afterLunch:
        return '13:00';
      case DoseSlot.beforeDinner:
        return '19:00';
      case DoseSlot.afterDinner:
        return '20:00';
      case DoseSlot.bedtime:
        return '22:00';
      case DoseSlot.custom:
        return null;
    }
  }

  /// Stable string key stored in Firestore.
  String get key => name;

  static DoseSlot fromKey(String? key) {
    return DoseSlot.values.firstWhere(
      (s) => s.name == key,
      orElse: () => DoseSlot.custom,
    );
  }
}

/// A single scheduled dose: a named slot plus the concrete time it resolves to.
/// Stored as a small map inside the medication document.
class DoseTime {
  final DoseSlot slot;
  final String time; // resolved "HH:mm" — always present, so existing logic works

  const DoseTime({required this.slot, required this.time});

  /// A friendly display like "After Breakfast · 8:00 AM" or just the time
  /// for custom slots.
  String display() {
    if (slot == DoseSlot.custom) return _to12h(time);
    return '${slot.label} · ${_to12h(time)}';
  }

  Map<String, dynamic> toMap() => {'slot': slot.key, 'time': time};

  factory DoseTime.fromMap(Map<String, dynamic> map) => DoseTime(
        slot: DoseSlotInfo.fromKey(map['slot'] as String?),
        time: (map['time'] as String?) ?? '08:00',
      );

  /// Backward compatibility: existing medications store plain "HH:mm" strings.
  /// Treat those as custom-time doses so nothing breaks.
  factory DoseTime.fromLegacy(String time) =>
      DoseTime(slot: DoseSlot.custom, time: time);

  static String _to12h(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }
}
