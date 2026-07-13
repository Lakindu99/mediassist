import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/appointment_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feedback_helpers.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/appointment.dart';
import 'appointment_form_screen.dart';

/// Shows the user's appointments in a live-updating, date-ordered list.
class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppointmentService();
    void addAppointment() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments', style: TextStyle(fontSize: 22))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addAppointment,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontSize: 18)),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: service.watchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading your appointments…');
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
          if (appts.isEmpty) {
            return EmptyState(
              icon: Icons.event,
              accent: AppColors.appointments,
              title: 'No appointments yet',
              message: 'Add an appointment to keep track of your doctor visits.',
              actionLabel: 'Add appointment',
              onAction: addAppointment,
            );
          }
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
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmAction(context,
        title: 'Delete this appointment?',
        message: 'This will remove it from your appointments.',
        confirmLabel: 'Delete', isDestructive: true);
    if (!ok) return;
    await service.deleteAppointment(appointment.id);
    showSuccessSnack(messenger, 'Appointment deleted');
  }
}
