import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/adaptive_provider.dart';
import '../../core/services/behaviour_tracker.dart';

/// Hidden researcher panel: controls adaptiveMode AND shows the latest tracked
/// behaviour metrics live (proof the engine is working; great for the viva).
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
                      ? 'ON — behaviour tracking active (Adaptive condition).'
                      : 'OFF — static control condition (no tracking).',
                  style: const TextStyle(fontSize: 14),
                ),
                value: adaptive.adaptiveMode,
                onChanged: (v) => context.read<AdaptiveProvider>().setAdaptiveMode(v),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Latest tracked session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Updates when a task completes or the app is backgrounded.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _latestSession(),
              builder: (context, snap) {
                if (!adaptive.adaptiveMode) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Turn Adaptive Mode on to begin tracking.',
                          style: TextStyle(fontSize: 15)),
                    ),
                  );
                }
                final d = snap.data;
                if (d == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No session data yet. Use the app, then return here.',
                          style: TextStyle(fontSize: 15)),
                    ),
                  );
                }
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _metric('M1  Avg task time', '${d['avgTaskTimeSec'] ?? 0} s'),
                        _metric('M2  Error rate',
                            '${((d['errorRate'] ?? 0) * 100).toStringAsFixed(0)}%  (${d['errorCount'] ?? 0}/${d['totalActions'] ?? 0})'),
                        _metric('M3  Hesitations', '${d['hesitationCount'] ?? 0}'),
                        _metric('M4  Retry taps', '${d['retryTaps'] ?? 0}'),
                        _metric('M5  Screen revisits', '${d['screenRevisits'] ?? 0}'),
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

  Widget _metric(String label, String value) {
    return ListTile(
      dense: false,
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }
}
