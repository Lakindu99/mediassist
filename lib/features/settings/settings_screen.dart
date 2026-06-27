import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_provider.dart';

/// Lets the user adjust text size and high-contrast mode. Everything applies
/// live, because the whole app listens to SettingsProvider.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility', style: TextStyle(fontSize: 22))),
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
                style: TextStyle(fontSize: 15, color: Colors.black54)),
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
                style: TextStyle(fontSize: 15, color: Colors.black54)),
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
