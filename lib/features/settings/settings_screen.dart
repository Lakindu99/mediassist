import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_provider.dart';
import '../../core/services/adaptive_provider.dart';
import '../researcher/researcher_panel.dart';
import '../../core/theme/app_theme.dart';

/// Accessibility settings (text size + high contrast), plus a clearly-marked
/// Researcher / Advanced section that controls the adaptive experiment. The
/// adaptive toggle lives here (discoverable in Settings) rather than only
/// behind a hidden long-press.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final adaptiveOn = context.watch<AdaptiveProvider>().adaptiveMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Live preview — scales and recolours as you change settings.
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Preview: Take 1 tablet at 8:00 AM',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Text Size',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Choose a comfortable reading size.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _sizeOption(context, 'Normal', 1.0, settings.fontScale),
                const SizedBox(width: 10),
                _sizeOption(context, 'Large', 1.2, settings.fontScale),
                const SizedBox(width: 10),
                _sizeOption(context, 'Extra Large', 1.35, settings.fontScale),
              ],
            ),
            const SizedBox(height: 32),

            const Text('High Contrast',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Makes text and colours easier to see.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('High contrast mode', style: TextStyle(fontSize: 18)),
                value: settings.highContrast,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onChanged: (v) =>
                    context.read<SettingsProvider>().setHighContrast(v),
              ),
            ),

            // ---------- Researcher / Advanced ----------
            const SizedBox(height: 40),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.science, color: Colors.deepPurple, size: 24),
                SizedBox(width: 8),
                Text('Researcher / Advanced',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'For research use. Controls the adaptive study condition. Leave off for '
              'the standard app.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.deepPurple.shade50,
              child: SwitchListTile(
                title: const Text('Adaptive Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  adaptiveOn
                      ? 'On — the interface adapts to the user (Adaptive condition).'
                      : 'Off — standard interface (Static control condition).',
                  style: const TextStyle(fontSize: 13),
                ),
                secondary: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                value: adaptiveOn,
                onChanged: (v) => context.read<AdaptiveProvider>().setAdaptiveMode(v),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('Open Researcher Panel',
                    style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResearcherPanel()),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sizeOption(
      BuildContext context, String label, double scale, double current) {
    final selected = (current - scale).abs() < 0.001;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<SettingsProvider>().setFontScale(scale),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            border: Border.all(
              color: selected ? scheme.primary : Colors.grey,
              width: selected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}
