import 'package:flutter/material.dart';
import '../../core/services/behaviour_tracker.dart';
import '../../core/services/medication_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/feedback_helpers.dart';
import '../../core/models/dose_slot.dart';
import '../../models/medication.dart';
import '../../core/theme/app_theme.dart';

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

  // The dose schedule (slot + resolved time). This is the source of truth in
  // the form; we derive the plain _times list from it when saving.
  final List<DoseTime> _schedule = [];
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
      _schedule.addAll(existing.schedule);
      _sortSchedule();
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

  void _sortSchedule() {
    _schedule.sort((a, b) => a.time.compareTo(b.time));
  }

  /// Step 1: choose a meal-relative slot (or custom). Step 2: confirm/adjust
  /// the time. This makes scheduling friendlier for elderly users.
  Future<void> _addDose() async {
    final slot = await showModalBottomSheet<DoseSlot>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('When should this be taken?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: DoseSlot.values.map((s) => ListTile(
                        leading: Icon(
                          s == DoseSlot.custom ? Icons.access_time : Icons.restaurant,
                          color: AppColors.teal,
                        ),
                        title: Text(s.label, style: const TextStyle(fontSize: 17)),
                        trailing: s.defaultTime != null
                            ? Text(DoseTime(slot: s, time: s.defaultTime!)
                                .display()
                                .split('· ')
                                .last)
                            : null,
                        onTap: () => Navigator.pop(context, s),
                      )).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (slot == null) return;

    // Determine the initial time: a named slot's default, or "now" for custom.
    String initialTime = slot.defaultTime ?? _nowHHmm();

    // For custom slots (and optionally to fine-tune named ones), open the clock.
    if (slot == DoseSlot.custom) {
      final picked = await _pickClock(initialTime);
      if (picked == null) return;
      initialTime = picked;
    }

    final dose = DoseTime(slot: slot, time: initialTime);
    // Avoid exact duplicates (same slot + time).
    final dup = _schedule
        .any((d) => d.slot == dose.slot && d.time == dose.time);
    if (!dup) {
      setState(() {
        _schedule.add(dose);
        _sortSchedule();
      });
    }
  }

  /// Let the user adjust the time of an existing named-slot dose by tapping it.
  Future<void> _editDoseTime(DoseTime dose) async {
    final picked = await _pickClock(dose.time);
    if (picked == null) return;
    setState(() {
      final i = _schedule.indexOf(dose);
      if (i != -1) {
        _schedule[i] = DoseTime(slot: dose.slot, time: picked);
        _sortSchedule();
      }
    });
  }

  Future<String?> _pickClock(String hhmm) async {
    final parts = hhmm.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  String _nowHHmm() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

    // Derive the resolved times list (source of truth) from the schedule.
    final times = _schedule.map((d) => d.time).toList()..sort();

    final med = Medication(
      id: widget.existing?.id ?? '',
      name: name,
      dosage: _dosageController.text.trim(),
      times: times,
      schedule: _schedule,
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
              const Text('When to take it:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Choose a mealtime or a custom time. Tap a time to adjust it.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              if (_schedule.isEmpty)
                const Text('No times added yet.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              ..._schedule.map((dose) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        dose.slot == DoseSlot.custom
                            ? Icons.access_time
                            : Icons.restaurant,
                        color: AppColors.teal,
                      ),
                      title: Text(dose.display(), style: const TextStyle(fontSize: 16)),
                      onTap: () => _editDoseTime(dose),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        tooltip: 'Remove',
                        onPressed: () => setState(() => _schedule.remove(dose)),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addDose,
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
