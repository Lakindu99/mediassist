import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_provider.dart';
import '../services/adaptive_engine.dart';
import '../../features/researcher/adaptation_log_screen.dart';

/// A prominent, always-visible indicator of the current adaptive support level.
/// This makes the adaptive engine's intelligence LEGIBLE — it shows not just
/// that the UI changed, but the support level, the reason, and which strategy
/// (rule-based vs ML) is driving it. Shown only in adaptive mode.
class AssistanceLevelCard extends StatelessWidget {
  const AssistanceLevelCard({super.key});

  static const _levels = [
    _LevelInfo('Standard Support', 'Interface at its normal level',
        Icons.check_circle_outline, Color(0xFF2E7D32)),
    _LevelInfo('Moderate Support', 'Text and buttons enlarged to assist you',
        Icons.trending_up, Color(0xFFEF6C00)),
    _LevelInfo('High Support', 'Maximum assistance: larger UI, high contrast, simplified',
        Icons.accessibility_new, Color(0xFFC62828)),
  ];

  @override
  Widget build(BuildContext context) {
    final on = context.watch<AdaptiveProvider>().adaptiveMode;
    if (!on) return const SizedBox.shrink();

    final engine = context.watch<AdaptiveEngine>();
    final level = engine.activeLevel.clamp(0, 2);
    final info = _levels[level];
    final strategy =
        engine.strategy == AdaptiveStrategy.ml ? 'Machine Learning' : 'Rule-based';

    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: info.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdaptationLogScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(info.icon, color: info.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.title,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: info.color)),
                        const SizedBox(height: 2),
                        Text(info.subtitle,
                            style: const TextStyle(
                                fontSize: 13.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              // Level meter — a simple 3-segment bar showing the support level.
              Row(
                children: List.generate(3, (i) {
                  final active = i <= level;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: active ? info.color : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.psychology, size: 15, color: Colors.deepPurple),
                  const SizedBox(width: 5),
                  Text('Deciding with: $strategy',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Text('Tap to see why',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _LevelInfo(this.title, this.subtitle, this.icon, this.color);
}
