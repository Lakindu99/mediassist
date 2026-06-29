import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/adherence_service.dart';

/// Shows a history of medication doses the user has marked as taken, with a
/// simple weekly summary. Data comes from the doseLogs the Today screen writes.
class AdherenceHistoryScreen extends StatelessWidget {
  const AdherenceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adherence = AdherenceService();
    return Scaffold(
      appBar: AppBar(title: const Text('Medication History', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Weekly summary card ----
            StreamBuilder<int>(
              stream: adherence.watchWeekCount(),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.insights, size: 40, color: Colors.teal),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$count',
                                  style: const TextStyle(
                                      fontSize: 32, fontWeight: FontWeight.bold)),
                              const Text('doses taken in the last 7 days',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Full history list ----
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: adherence.watchAllLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 80, color: Colors.teal),
                            SizedBox(height: 16),
                            Text('No history yet',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(
                              'When you mark medicines as taken on the Today screen, they will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final name = log['medName'] ?? 'Medication';
                      final time = log['time'] ?? '';
                      final takenAt = log['takenAt'];
                      String takenText = '';
                      if (takenAt is Timestamp) {
                        takenText = DateFormat('EEE, d MMM').format(takenAt.toDate());
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE0F2F1),
                            child: Icon(Icons.check, color: Colors.teal),
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600)),
                          subtitle: Text('Scheduled for $time',
                              style: const TextStyle(fontSize: 15)),
                          trailing: Text(takenText,
                              style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
