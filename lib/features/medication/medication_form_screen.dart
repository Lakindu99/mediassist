import 'package:flutter/material.dart';
import '../../core/services/behaviour_tracker.dart';
import '../../core/services/medication_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/feedback_helpers.dart';
import '../../models/medication.dart';

/// Form to add a new medication or edit an existing one.
/// If 'existing' is provided, it's edit mode; otherwise it's add mode.
class MedicationFormScreen extends StatefulWidget {
  final Medication? existing;
  const MedicationFormScreen({super.key, this.existing});

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _service = MedicationService();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _times = [];
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _dosageController.text = existing.dosage;
      _notesController.text = existing.notes;
      _times.addAll(existing.times);
    }
    if (!_isEditing) BehaviourTracker.instance.startTask('add_medication');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_times.contains(formatted)) {
        setState(() {
          _times.add(formatted);
          _times.sort();
        });
      }
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      BehaviourTracker.instance.logError('medication_name_empty');
      _showMessage('Please enter the medication name.');
      return;
    }
    setState(() => _isLoading = true);
    final med = Medication(
      id: widget.existing?.id ?? '',
      name: name,
      dosage: _dosageController.text.trim(),
      times: _times,
      notes: _notesController.text.trim(),
    );
    try {
      if (_isEditing) {
        await _service.updateMedication(med);
      } else {
        await _service.addMedication(med);
        await BehaviourTracker.instance.endTask('add_medication');
      }
      if (mounted) {
        showSuccessSnack(messenger, _isEditing ? 'Medicine updated' : 'Medicine saved');
        navigator.pop();
      }
    } catch (e) {
      _showMessage('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 16))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication',
            style: const TextStyle(fontSize: 22)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                  controller: _nameController,
                  label: 'Medication Name',
                  icon: Icons.medication),
              const SizedBox(height: 20),
              AppTextField(
                  controller: _dosageController,
                  label: 'Dosage (e.g. 1 tablet, 100mg)',
                  icon: Icons.straighten),
              const SizedBox(height: 24),
              const Text('Times to take:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_times.isEmpty)
                const Text('No times added yet.',
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times
                    .map((t) => Chip(
                          avatar: const Icon(Icons.access_time, size: 18),
                          label: Text(t, style: const TextStyle(fontSize: 16)),
                          onDeleted: () => setState(() => _times.remove(t)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.add_alarm, size: 22),
                label: const Text('Add a time', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                  controller: _notesController,
                  label: 'Notes (optional, e.g. after food)',
                  icon: Icons.note),
              const SizedBox(height: 32),
              AppButton(
                label: _isEditing ? 'Save Changes' : 'Add Medication',
                icon: Icons.check,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
