import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/appointment_service.dart';
import '../../models/appointment.dart';
import 'appointment_form_screen.dart';

/// Shows the user's appointments in a live-updating, date-ordered list.
class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppointmentService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments', style: TextStyle(fontSize: 22))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontSize: 18)),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: service.watchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load appointments. Please try again.',
                    style: TextStyle(fontSize: 18)),
              ),
            );
          }
          final appts = snapshot.data ?? [];
          if (appts.isEmpty) return _emptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appts.length,
            itemBuilder: (context, index) =>
                _AppointmentCard(appointment: appts[index], service: service),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 90, color: Colors.indigo),
          SizedBox(height: 16),
          Text('No appointments yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text('Tap the "Add" button to add your first appointment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final AppointmentService service;
  const _AppointmentCard({required this.appointment, required this.service});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE, d MMM yyyy').format(appointment.dateTime);
    final timeText = DateFormat('h:mm a').format(appointment.dateTime);
    final isPast = appointment.dateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, size: 36, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(appointment.doctor,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Past', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today, dateText),
            const SizedBox(height: 6),
            _infoRow(Icons.access_time, timeText),
            if (appointment.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.location_on, appointment.location),
            ],
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(appointment.notes, style: const TextStyle(fontSize: 15)),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AppointmentFormScreen(existing: appointment),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 22),
                  label: const Text('Edit', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(fontSize: 16, color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete appointment?', style: TextStyle(fontSize: 20)),
        content: Text(
          'Are you sure you want to delete the appointment with "${appointment.doctor}"? This cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(fontSize: 16, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.deleteAppointment(appointment.id);
    }
  }
}
