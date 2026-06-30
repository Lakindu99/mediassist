import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/adaptive_provider.dart';

/// Hidden panel for the researcher to control the experiment. Reached by
/// long-pressing the 'MediAssist' title on the dashboard, so participants
/// never see or change it. Holds the adaptiveMode switch (Static vs Adaptive).
class ResearcherPanel extends StatelessWidget {
  const ResearcherPanel({super.key});

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
                      ? 'ON — behaviour tracking & adaptive UI active (Adaptive condition).'
                      : 'OFF — app behaves as the static control condition.',
                  style: const TextStyle(fontSize: 14),
                ),
                value: adaptive.adaptiveMode,
                onChanged: (v) => context.read<AdaptiveProvider>().setAdaptiveMode(v),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'For research control only. Set the mode before handing the device to a participant. '
                  'In the Adaptive condition (later stages), the app silently tracks interaction behaviour '
                  'and adapts the interface to reduce cognitive load.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
