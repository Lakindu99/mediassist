import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/medication_service.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/adherence_service.dart';
import '../../models/medication.dart';
import '../../models/appointment.dart';

/// The most important screen for elderly users: shows ONLY what's due today —
/// medications (with a big "Take" button) and appointments. Reduces cognitive
/// load by removing everything not relevant right now.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medService = MedicationService();
    final apptService = AppointmentService();
    final adherence = AdherenceService();
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Today', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(DateFormat('EEEE, d MMMM').format(today),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Here is your plan for today.',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 24),

            // ---------- Medications due today ----------
            _sectionHeader(Icons.medication, 'Medications', Colors.teal),
            const SizedBox(height: 12),
            StreamBuilder<List<Medication>>(
              stream: medService.watchMedications(),
              builder: (context, medSnap) {
                if (!medSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                // Build today's dose list: each medication × each of its times.
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
                  stream: adherence.watchTakenToday(),
                  builder: (context, takenSnap) {
                    final taken = takenSnap.data ?? <String>{};
                    return Column(
                      children: doses.map((d) {
                        final key = AdherenceService.doseKey(d.med.id, today, d.time);
                        final isTaken = taken.contains(key);
                        return _DoseCard(
                          dose: d,
                          isTaken: isTaken,
                          onToggle: () async {
                            if (isTaken) {
                              await adherence.undoTaken(medId: d.med.id, time: d.time);
                            } else {
                              await adherence.markTaken(
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

            // ---------- Appointments today ----------
            _sectionHeader(Icons.event, 'Appointments', Colors.indigo),
            const SizedBox(height: 12),
            StreamBuilder<List<Appointment>>(
              stream: apptService.watchAppointments(),
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
  final VoidCallback onToggle;
  const _DoseCard(
      {required this.dose, required this.isTaken, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isTaken ? Colors.green.shade50 : null,
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
