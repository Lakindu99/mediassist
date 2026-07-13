import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/medication_service.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/adherence_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/adaptive_provider.dart';
import '../../core/services/adaptive_engine.dart';
import '../../models/medication.dart';
import '../../models/appointment.dart';

/// The most important screen for elderly users: shows ONLY what's due today.
/// Includes a "Read aloud" button (text-to-speech) for users with weak
/// eyesight; in adaptive mode, when the engine detects the user is struggling,
/// the plan is read out automatically on open.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final MedicationService _medService = MedicationService();
  final AppointmentService _apptService = AppointmentService();
  final AdherenceService _adherence = AdherenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDueReminders();
      // Adaptive tie-in: if the engine has escalated to strong adaptation,
      // read the plan aloud automatically to support the struggling user.
      final on = context.read<AdaptiveProvider>().adaptiveMode;
      final strong = on && context.read<AdaptiveEngine>().activeLevel >= 2;
      if (strong) _readPlanAloud();
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  bool _isDue(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return !now.isBefore(DateTime(now.year, now.month, now.day, h, m));
  }

  /// Turn "08:30" into a spoken form like "8 30 A M".
  String _spokenTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    final ampm = h < 12 ? 'A M' : 'P M';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return m == 0 ? '$h12 $ampm' : '$h12 ${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Compose a friendly spoken summary of today's plan and read it aloud.
  Future<void> _readPlanAloud() async {
    try {
      final meds = await _medService.watchMedications().first;
      final appts = await _apptService.watchAppointments().first;
      final today = DateTime.now();

      final buffer = StringBuffer('Here is your plan for today. ');
      final doses = <_Dose>[];
      for (final m in meds) {
        for (final t in m.times) {
          doses.add(_Dose(med: m, time: t));
        }
      }
      doses.sort((a, b) => a.time.compareTo(b.time));

      if (doses.isEmpty) {
        buffer.write('You have no medications scheduled today. ');
      } else {
        buffer.write('Your medicines. ');
        for (final d in doses) {
          final dosage = d.med.dosage.isNotEmpty ? ', ${d.med.dosage}, ' : ', ';
          buffer.write('${d.med.name}$dosage at ${_spokenTime(d.time)}. ');
        }
      }

      final todays = appts.where((a) =>
          a.dateTime.year == today.year &&
          a.dateTime.month == today.month &&
          a.dateTime.day == today.day).toList();
      if (todays.isNotEmpty) {
        buffer.write('Your appointments. ');
        for (final a in todays) {
          buffer.write('${a.doctor} at ${DateFormat('h:mm a').format(a.dateTime)}. ');
        }
      }
      await TtsService.instance.speak(buffer.toString());
    } catch (_) {
      // Ignore read-aloud failures (e.g. offline); it's a non-critical aid.
    }
  }

  Future<void> _checkDueReminders() async {
    try {
      final meds = await _medService.watchMedications().first;
      final taken = await _adherence.watchTakenToday().first;
      final today = DateTime.now();

      final due = <String>[];
      for (final m in meds) {
        for (final t in m.times) {
          final key = AdherenceService.doseKey(m.id, today, t);
          if (_isDue(t) && !taken.contains(key)) {
            due.add('${m.name} at $t');
          }
        }
      }
      if (due.isEmpty || !mounted) return;

      await NotificationService.instance.showNow(
        900,
        'Medication reminder',
        due.length == 1
            ? 'It is time to take: ${due.first}'
            : 'You have ${due.length} medications due now.',
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.deepOrange, size: 28),
              SizedBox(width: 8),
              Text('Medication due', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('These are due now. Tap "Take" on the list to mark them.',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ...due.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, size: 20, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Plan", style: TextStyle(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 28),
            tooltip: 'Read aloud',
            onPressed: _readPlanAloud,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(DateFormat('EEEE, d MMMM').format(today),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                // Prominent read-aloud button (elderly-friendly, clearly labelled).
                TextButton.icon(
                  onPressed: _readPlanAloud,
                  icon: const Icon(Icons.volume_up, size: 24),
                  label: const Text('Listen', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Here is your plan for today.',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 24),

            _sectionHeader(Icons.medication, 'Medications', Colors.teal),
            const SizedBox(height: 12),
            StreamBuilder<List<Medication>>(
              stream: _medService.watchMedications(),
              builder: (context, medSnap) {
                if (!medSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final doses = <_Dose>[];
                for (final m in medSnap.data!) {
                  for (final t in m.times) {
                    doses.add(_Dose(med: m, time: t));
                  }
                }
                doses.sort((a, b) => a.time.compareTo(b.time));
                if (doses.isEmpty) {
                  return _emptyCard('No medications scheduled for today.');
                }
                return StreamBuilder<Set<String>>(
                  stream: _adherence.watchTakenToday(),
                  builder: (context, takenSnap) {
                    final taken = takenSnap.data ?? <String>{};
                    return Column(
                      children: doses.map((d) {
                        final key = AdherenceService.doseKey(d.med.id, today, d.time);
                        final isTaken = taken.contains(key);
                        final isDue = !isTaken && _isDue(d.time);
                        return _DoseCard(
                          dose: d,
                          isTaken: isTaken,
                          isDue: isDue,
                          onToggle: () async {
                            if (isTaken) {
                              await _adherence.undoTaken(medId: d.med.id, time: d.time);
                            } else {
                              await _adherence.markTaken(
                                  medId: d.med.id, medName: d.med.name, time: d.time);
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),
            _sectionHeader(Icons.event, 'Appointments', Colors.indigo),
            const SizedBox(height: 12),
            StreamBuilder<List<Appointment>>(
              stream: _apptService.watchAppointments(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final todays = snap.data!.where((a) =>
                    a.dateTime.year == today.year &&
                    a.dateTime.month == today.month &&
                    a.dateTime.day == today.day).toList();
                if (todays.isEmpty) return _emptyCard('No appointments today.');
                return Column(
                  children:
                      todays.map((a) => _TodayAppointmentCard(appointment: a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ),
    );
  }
}

class _Dose {
  final Medication med;
  final String time;
  _Dose({required this.med, required this.time});
}

class _DoseCard extends StatelessWidget {
  final _Dose dose;
  final bool isTaken;
  final bool isDue;
  final VoidCallback onToggle;
  const _DoseCard({
    required this.dose,
    required this.isTaken,
    required this.isDue,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color? cardColor;
    if (isTaken) {
      cardColor = Colors.green.shade50;
    } else if (isDue) {
      cardColor = Colors.orange.shade50;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDue && !isTaken
            ? const BorderSide(color: Colors.deepOrange, width: 1.5)
            : BorderSide.none,
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(dose.time,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dose.med.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  if (dose.med.dosage.isNotEmpty)
                    Text(dose.med.dosage,
                        style: const TextStyle(fontSize: 15, color: Colors.black54)),
                  if (isDue && !isTaken)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Due now',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isTaken)
              TextButton.icon(
                onPressed: onToggle,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                label: const Text('Taken',
                    style: TextStyle(fontSize: 15, color: Colors.green)),
              )
            else
              ElevatedButton(
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Take', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _TodayAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('h:mm a').format(appointment.dateTime);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.medical_services, size: 32, color: Colors.indigo),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.doctor,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(timeText,
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  if (appointment.location.isNotEmpty)
                    Text(appointment.location,
                        style: const TextStyle(fontSize: 15, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
