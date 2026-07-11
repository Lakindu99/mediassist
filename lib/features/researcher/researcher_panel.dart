import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/adaptive_provider.dart';
import '../../core/services/adaptive_engine.dart';
import 'adaptation_log_screen.dart';

/// Hidden researcher panel: controls adaptiveMode & strategy, shows the live
/// rule-based vs ML comparison, preview controls, and the tracked metrics.
class ResearcherPanel extends StatelessWidget {
  const ResearcherPanel({super.key});

  static const _levelName = ['None (0)', 'Mild (1)', 'Strong (2)'];

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
    final on = adaptive.adaptiveMode;

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
                  on ? 'ON — tracking + adaptation active.'
                     : 'OFF — static control (no tracking, no adaptation).',
                  style: const TextStyle(fontSize: 14),
                ),
                value: on,
                onChanged: (v) => context.read<AdaptiveProvider>().setAdaptiveMode(v),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Adaptation strategy (drives the UI)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<AdaptiveStrategy>(
              segments: const [
                ButtonSegment(value: AdaptiveStrategy.ruleBased,
                    label: Text('Rule-based'), icon: Icon(Icons.rule)),
                ButtonSegment(value: AdaptiveStrategy.ml,
                    label: Text('ML'), icon: Icon(Icons.psychology)),
              ],
              selected: {engine.strategy},
              onSelectionChanged: on
                  ? (set) => context.read<AdaptiveEngine>().setStrategy(set.first)
                  : null,
            ),
            const SizedBox(height: 20),

            const Text('Rule-based vs ML (live)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _decisionBox('Rule-based', engine.ruleLevel,
                            engine.strategy == AdaptiveStrategy.ruleBased)),
                        const SizedBox(width: 10),
                        Expanded(child: _decisionBox('ML', engine.mlLevel,
                            engine.strategy == AdaptiveStrategy.ml)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: engine.ruleLevel == engine.mlLevel
                            ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        engine.ruleLevel == engine.mlLevel
                            ? 'Agree — both chose level ${engine.ruleLevel}'
                            : 'Differ — rule ${engine.ruleLevel} vs ML ${engine.mlLevel}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: engine.ruleLevel == engine.mlLevel
                              ? Colors.green.shade800 : Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Driving the UI: level ${engine.activeLevel}'
                      '${engine.isPreviewing ? "  (preview)" : ""}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdaptationLogScreen())),
              icon: const Icon(Icons.list_alt),
              label: const Text('View adaptation log', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 20),

            const Text('Preview adaptation (demo)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
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

            const Text('Latest tracked session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _latestSession(),
              builder: (context, snap) {
                if (!on) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16),
                      child: Text('Turn Adaptive Mode on to begin tracking.',
                          style: TextStyle(fontSize: 15))));
                }
                final d = snap.data;
                if (d == null) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16),
                      child: Text('No session data yet. Use the app, then return.',
                          style: TextStyle(fontSize: 15))));
                }
                final agree = d['ruleMlAgreements'] ?? 0;
                final total = d['ruleMlDecisions'] ?? 0;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _row('M1  Avg task time', '${d['avgTaskTimeSec'] ?? 0} s'),
                        _row('M2  Error rate',
                            '${((d['errorRate'] ?? 0) * 100).toStringAsFixed(0)}%'),
                        _row('M3  Hesitations', '${d['hesitationCount'] ?? 0}'),
                        _row('M4  Retry taps', '${d['retryTaps'] ?? 0}'),
                        _row('M5  Screen revisits', '${d['screenRevisits'] ?? 0}'),
                        const Divider(),
                        _row('Rule/ML agreement',
                            total == 0 ? '—' : '$agree / $total decisions'),
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

  Widget _decisionBox(String title, int level, bool active) {
    const palette = [Colors.green, Colors.orange, Colors.red];
    final c = palette[level];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? c : Colors.grey.shade300, width: active ? 2.5 : 1),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_levelName[level],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)),
          if (active)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('driving UI', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ),
        ],
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
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }
}
