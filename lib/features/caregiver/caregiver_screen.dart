import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/caregiver_service.dart';
import '../../core/services/medication_service.dart';
import '../../core/services/adherence_service.dart';
import '../../core/services/tts_service.dart';
import '../../models/app_user.dart';
import '../../models/medication.dart';

/// One screen, two roles: an elderly user sees their share code; a caregiver
/// links to an elderly user and monitors today's medication status.
class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: authService.getCurrentUserProfile(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return snap.data!.role == UserRole.elderly
                ? const _ElderlyShareView()
                : const _CaregiverMonitorView();
          },
        ),
      ),
    );
  }
}

// ---------- ELDERLY: show/generate a share code, and send it ----------
class _ElderlyShareView extends StatelessWidget {
  const _ElderlyShareView();

  @override
  Widget build(BuildContext context) {
    final service = CaregiverService();
    return StreamBuilder<String?>(
      stream: service.watchMyShareCode(),
      builder: (context, snap) {
        final code = snap.data;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.family_restroom, size: 70, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('Share with your caregiver',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Give this code to your caregiver. They can then see your medicines '
              'and appointments, and whether you have taken your medicines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Your code', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      code ?? '——————',
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: Colors.teal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Send / Read aloud / Copy — only shown once a code exists.
            if (code != null) ...[
              Builder(
                builder: (btnContext) => SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Send to caregiver', style: TextStyle(fontSize: 17)),
                    onPressed: () => _shareCode(btnContext, code),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Read aloud', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _readCode(code),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _copyCode(context, code),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(code == null ? 'Generate code' : 'Generate new code',
                    style: const TextStyle(fontSize: 17)),
                onPressed: () async {
                  await service.generateShareCode();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New code generated.',
                          style: TextStyle(fontSize: 15))),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCode(BuildContext context, String code) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final message =
        'Hello! Please connect to my MediAssist app to help me manage my medicines '
        'and appointments.\n\nMy code is: $code\n\n'
        'In MediAssist, open Caregiver and enter this code.';
    await SharePlus.instance.share(ShareParams(
      text: message,
      subject: 'My MediAssist caregiver code',
      sharePositionOrigin: origin,
    ));
  }

  Future<void> _readCode(String code) async {
    final spoken = code.split('').join(', '); // read each character clearly
    await TtsService.instance.speak('Your caregiver code is: $spoken');
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied to clipboard.',
            style: TextStyle(fontSize: 15))),
      );
    }
  }
}

// ---------- CAREGIVER: link, then monitor ----------
class _CaregiverMonitorView extends StatelessWidget {
  const _CaregiverMonitorView();

  @override
  Widget build(BuildContext context) {
    final service = CaregiverService();
    return StreamBuilder<Map<String, String>?>(
      stream: service.watchLinkedElderly(),
      builder: (context, snap) {
        final linked = snap.data;
        if (linked == null) return _LinkForm(service: service);
        return _MonitorView(
          elderlyUid: linked['uid']!,
          elderlyName: linked['name']!,
          service: service,
        );
      },
    );
  }
}

class _LinkForm extends StatefulWidget {
  final CaregiverService service;
  const _LinkForm({required this.service});
  @override
  State<_LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends State<_LinkForm> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final error = await widget.service.linkByCode(code);
    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error, style: const TextStyle(fontSize: 15))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.link, size: 70, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text('Connect to an elderly user',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Ask the elderly person to open MediAssist → Caregiver, and read you their code. Enter it below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 4),
            decoration: InputDecoration(
              labelText: 'Enter code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Connect', style: TextStyle(fontSize: 17)),
              onPressed: _loading ? null : _link,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _MonitorView extends StatelessWidget {
  final String elderlyUid;
  final String elderlyName;
  final CaregiverService service;
  const _MonitorView({
    required this.elderlyUid,
    required this.elderlyName,
    required this.service,
  });

  bool _isDue(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return !now.isBefore(DateTime(now.year, now.month, now.day, h, m));
  }

  @override
  Widget build(BuildContext context) {
    final medService = MedicationService();
    final adherence = AdherenceService();
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.teal.shade100,
              child: Text(
                elderlyName.isNotEmpty ? elderlyName[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(elderlyName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Monitoring today',
                      style: TextStyle(fontSize: 15, color: Colors.black54)),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Disconnect?', style: TextStyle(fontSize: 20)),
                    content: Text('Stop monitoring $elderlyName?',
                        style: const TextStyle(fontSize: 16)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Disconnect',
                              style: TextStyle(fontSize: 16, color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) await service.unlink();
              },
              child: const Text('Unlink', style: TextStyle(fontSize: 15, color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<Medication>>(
          stream: medService.watchMedicationsFor(elderlyUid),
          builder: (context, medSnap) {
            if (!medSnap.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()));
            }
            final doses = <_MonitorDose>[];
            for (final m in medSnap.data!) {
              for (final t in m.times) {
                doses.add(_MonitorDose(med: m, time: t));
              }
            }
            doses.sort((a, b) => a.time.compareTo(b.time));
            if (doses.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No medications to monitor yet.', style: TextStyle(fontSize: 16)),
                ),
              );
            }
            return StreamBuilder<Set<String>>(
              stream: adherence.watchTakenTodayFor(elderlyUid),
              builder: (context, takenSnap) {
                final taken = takenSnap.data ?? <String>{};
                final missedCount = doses.where((d) {
                  final key = AdherenceService.doseKey(d.med.id, today, d.time);
                  return _isDue(d.time) && !taken.contains(key);
                }).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (missedCount > 0)
                      Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$missedCount dose${missedCount > 1 ? 's' : ''} missed or due now',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...doses.map((d) {
                      final key = AdherenceService.doseKey(d.med.id, today, d.time);
                      final isTaken = taken.contains(key);
                      final isMissed = !isTaken && _isDue(d.time);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isTaken
                            ? Colors.green.shade50
                            : (isMissed ? Colors.red.shade50 : null),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Text(d.time,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          title: Text(d.med.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600)),
                          subtitle: d.med.dosage.isNotEmpty
                              ? Text(d.med.dosage, style: const TextStyle(fontSize: 14))
                              : null,
                          trailing: isTaken
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 26)
                              : (isMissed
                                  ? const Icon(Icons.cancel, color: Colors.red, size: 26)
                                  : const Icon(Icons.schedule, color: Colors.grey, size: 26)),
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _MonitorDose {
  final Medication med;
  final String time;
  _MonitorDose({required this.med, required this.time});
}
