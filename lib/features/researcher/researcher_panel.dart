import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/adaptive_provider.dart';
import '../../core/services/adaptive_engine.dart';

class ResearcherPanel extends StatelessWidget {
  const ResearcherPanel({super.key});

  Stream<Map<String, dynamic>?> _latestSession() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('behaviourSessions')
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : s.docs.first.data());
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.watch<AdaptiveProvider>();
    final engine = context.watch<AdaptiveEngine>();
    return Scaffold(
      appBar: AppBar(title: const Text('Researcher Panel', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Adaptive Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  adaptive.adaptiveMode
                      ? 'ON — tracking + adaptation active.'
                      : 'OFF — static control (no tracking, no adaptation).',
                  style: const TextStyle(fontSize: 14),
                ),
                value: adaptive.adaptiveMode,
                onChanged: (v) => context.read<AdaptiveProvider>().setAdaptiveMode(v),
              ),
            ),
            const SizedBox(height: 20),

            // ----- Live adaptation state -----
            const Text('Current adaptation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _row('Font level', '${engine.fontLevel}  (x${engine.fontScale})'),
                    _row('Button level', '${engine.buttonLevel}  (x${engine.buttonScale})'),
                    _row('High contrast', engine.forceHighContrast ? 'ON' : 'off'),
                    _row('Simplified nav', engine.simplifyNav ? 'ON' : 'off'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ----- Demo/testing preview controls -----
            const Text('Preview adaptation (demo/testing)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Force a level to demonstrate the UI instantly. "Auto" returns to live behaviour-driven rules.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                _previewBtn(context, 'Auto', null),
                const SizedBox(width: 8),
                _previewBtn(context, 'Mild', 1),
                const SizedBox(width: 8),
                _previewBtn(context, 'Strong', 2),
              ],
            ),
            const SizedBox(height: 20),

            // ----- Live tracked metrics -----
            const Text('Latest tracked session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _latestSession(),
              builder: (context, snap) {
                if (!adaptive.adaptiveMode) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16),
                      child: Text('Turn Adaptive Mode on to begin tracking.', style: TextStyle(fontSize: 15))));
                }
                final d = snap.data;
                if (d == null) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16),
                      child: Text('No session data yet. Use the app, then return here.', style: TextStyle(fontSize: 15))));
                }
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _row('M1  Avg task time', '${d['avgTaskTimeSec'] ?? 0} s'),
                        _row('M2  Error rate',
                            '${((d['errorRate'] ?? 0) * 100).toStringAsFixed(0)}%  (${d['errorCount'] ?? 0}/${d['totalActions'] ?? 0})'),
                        _row('M3  Hesitations', '${d['hesitationCount'] ?? 0}'),
                        _row('M4  Retry taps', '${d['retryTaps'] ?? 0}'),
                        _row('M5  Screen revisits', '${d['screenRevisits'] ?? 0}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewBtn(BuildContext context, String label, int? level) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => context.read<AdaptiveEngine>().setPreview(level),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }
}
