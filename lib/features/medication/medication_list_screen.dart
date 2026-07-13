import 'package:flutter/material.dart';
import '../../core/services/medication_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feedback_helpers.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/medication.dart';
import 'medication_form_screen.dart';

/// Shows the user's medications in a live-updating list. Add via the button,
/// tap Edit to change one, tap Delete to remove (with confirmation).
class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MedicationService();
    void addMedication() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MedicationFormScreen()),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('My Medications', style: TextStyle(fontSize: 22))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addMedication,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontSize: 18)),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: service.watchMedications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading your medicines…');
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load medications. Please try again.',
                    style: TextStyle(fontSize: 18)),
              ),
            );
          }
          final meds = snapshot.data ?? [];
          if (meds.isEmpty) {
            return EmptyState(
              icon: Icons.medication,
              accent: AppColors.medications,
              title: 'No medicines yet',
              message: 'Add your first medicine to start tracking your daily doses.',
              actionLabel: 'Add medicine',
              onAction: addMedication,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (context, index) =>
                _MedicationCard(medication: meds[index], service: service),
          );
        },
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final MedicationService service;
  const _MedicationCard({required this.medication, required this.service});

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.medication, size: 36, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (medication.dosage.isNotEmpty)
                        Text(medication.dosage,
                            style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            if (medication.times.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: medication.times
                    .map((t) => Chip(
                          avatar: const Icon(Icons.access_time, size: 18),
                          label: Text(t, style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
              ),
            ],
            if (medication.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(medication.notes, style: const TextStyle(fontSize: 15)),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MedicationFormScreen(existing: medication),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmAction(context,
        title: 'Delete this medicine?',
        message: 'This will remove it from your list. You can add it again later.',
        confirmLabel: 'Delete', isDestructive: true);
    if (!ok) return;
    await service.deleteMedication(medication.id);
    showSuccessSnack(messenger, 'Medicine deleted');
  }
}
