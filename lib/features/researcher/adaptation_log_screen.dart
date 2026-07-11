import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/adaptation_log_service.dart';

/// A timeline of every adaptation event — the evidence trail for the thesis.
class AdaptationLogScreen extends StatelessWidget {
  const AdaptationLogScreen({super.key});
  static const _levelName = ['None', 'Mild', 'Strong'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptation Log', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdaptationLogService.instance.watchLog(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final logs = snap.data!;
            if (logs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No adaptations recorded yet. Use the app in adaptive mode to generate entries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, i) {
                final e = logs[i];
                final ts = e['timestamp'];
                final timeText =
                    ts is Timestamp ? DateFormat('d MMM yyyy, h:mm:ss a').format(ts.toDate()) : '';
                final from = e['fromLevel'] ?? 0;
                final to = e['toLevel'] ?? 0;
                final up = to >= from;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(up ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                        color: up ? Colors.deepOrange : Colors.green, size: 30),
                    title: Text('${_levelName[from]}  →  ${_levelName[to]}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${e['reason'] ?? ''}   ·   strategy: ${e['strategy'] ?? ''}\n$timeText',
                      style: const TextStyle(fontSize: 13),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
