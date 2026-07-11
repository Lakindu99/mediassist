import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_provider.dart';
import '../services/adaptive_engine.dart';

/// A gentle banner that explains the current adaptation to the user (adaptive
/// mode only). Mitigates a known adaptive-UI problem: users get confused when
/// the interface changes without explanation. Hidden when there is no active
/// adaptation.
class AdaptiveRecommendationBanner extends StatelessWidget {
  const AdaptiveRecommendationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final on = context.watch<AdaptiveProvider>().adaptiveMode;
    final rec = on ? context.watch<AdaptiveEngine>().currentRecommendation : null;
    if (rec == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: Colors.deepPurple, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Text(rec, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
