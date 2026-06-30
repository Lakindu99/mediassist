import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/behaviour_tracker.dart';
import '../../core/services/appointment_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/appointment.dart';

/// Form to add a new appointment or edit an existing one.
/// If 'existing' is provided, it's edit mode; otherwise add mode.
class AppointmentFormScreen extends StatefulWidget {
  final Appointment? existing;
  const AppointmentFormScreen({super.key, this.existing});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _service = AppointmentService();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _doctorController.text = e.doctor;
      _locationController.text = e.location;
      _notesController.text = e.notes;
      _selectedDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      _selectedTime = TimeOfDay(hour: e.dateTime.hour, minute: e.dateTime.minute);
    }
    if (!_isEditing) BehaviourTracker.instance.startTask('add_appointment');
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final doctor = _doctorController.text.trim();
    if (doctor.isEmpty) {
      BehaviourTracker.instance.logError('appointment_field_empty');
      _showMessage('Please enter the doctor or appointment name.');
      return;
    }
    if (_selectedDate == null) {
      _showMessage('Please choose a date.');
      return;
    }
    if (_selectedTime == null) {
      _showMessage('Please choose a time.');
      return;
    }

    setState(() => _isLoading = true);
    final dt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );
    final appt = Appointment(
      id: widget.existing?.id ?? '',
      doctor: doctor,
      dateTime: dt,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
    );
    try {
      if (_isEditing) {
        await _service.updateAppointment(appt);
      } else {
        await _service.addAppointment(appt);
        await BehaviourTracker.instance.endTask('add_appointment');
      }
      if (mounted) Navigator.of(context).pop();
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
    final dateText = _selectedDate == null
        ? 'Tap to choose'
        : DateFormat('EEE, d MMM yyyy').format(_selectedDate!);
    final timeText = _selectedTime == null ? 'Tap to choose' : _selectedTime!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Appointment' : 'Add Appointment',
            style: const TextStyle(fontSize: 22)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                  controller: _doctorController,
                  label: 'Doctor / Appointment',
                  icon: Icons.medical_services),
              const SizedBox(height: 20),
              _pickerTile(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateText,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              _pickerTile(
                icon: Icons.access_time,
                label: 'Time',
                value: timeText,
                onTap: _pickTime,
              ),
              const SizedBox(height: 20),
              AppTextField(
                  controller: _locationController,
                  label: 'Location (e.g. City Clinic)',
                  icon: Icons.location_on),
              const SizedBox(height: 20),
              AppTextField(
                  controller: _notesController,
                  label: 'Notes (optional)',
                  icon: Icons.note),
              const SizedBox(height: 32),
              AppButton(
                label: _isEditing ? 'Save Changes' : 'Add Appointment',
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

  /// A large, tappable tile that shows a chosen date or time.
  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: Colors.indigo),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
