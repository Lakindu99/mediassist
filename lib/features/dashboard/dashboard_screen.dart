import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/adaptive_provider.dart';
import '../../core/services/adaptive_engine.dart';
import '../today/today_screen.dart';
import '../medication/medication_list_screen.dart';
import '../appointment/appointment_list_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../history/adherence_history_screen.dart';
import '../caregiver/caregiver_screen.dart';
import '../researcher/researcher_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adaptiveOn = context.watch<AdaptiveProvider>().adaptiveMode;
    final simplified = adaptiveOn && context.watch<AdaptiveEngine>().simplifyNav;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ResearcherPanel()),
          ),
          child: const Text('MediAssist', style: TextStyle(fontSize: 22)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
            tooltip: 'Accessibility settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, size: 26),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Text('What would you like to do?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (adaptiveOn) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(Icons.auto_awesome, 'Adaptive Mode active', Colors.deepPurple),
                    if (simplified) ...[
                      const SizedBox(width: 8),
                      _chip(Icons.view_agenda, 'Simplified view', Colors.blueGrey),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _DashboardTile(
                icon: Icons.today,
                title: "Today's Plan",
                subtitle: 'See what is due today',
                color: Colors.deepOrange,
                simplified: simplified,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: 'today'),
                    builder: (_) => const TodayScreen())),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.medication,
                title: 'My Medications',
                subtitle: 'View and manage your medicines',
                color: Colors.teal,
                simplified: simplified,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: 'medications'),
                    builder: (_) => const MedicationListScreen())),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.calendar_month,
                title: 'My Appointments',
                subtitle: 'View and manage your appointments',
                color: Colors.indigo,
                simplified: simplified,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: 'appointments'),
                    builder: (_) => const AppointmentListScreen())),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.history,
                title: 'Medication History',
                subtitle: 'See doses you have taken',
                color: Colors.purple,
                simplified: simplified,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: 'history'),
                    builder: (_) => const AdherenceHistoryScreen())),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.people,
                title: 'Caregiver',
                subtitle: 'Share access or monitor a loved one',
                color: Colors.brown,
                simplified: simplified,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    settings: const RouteSettings(name: 'caregiver'),
                    builder: (_) => const CaregiverScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool simplified;
  final VoidCallback onTap;
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.simplified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(simplified ? 24 : 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: simplified ? 34 : 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: simplified ? 36 : 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    // In simplified mode, hide the subtitle to reduce clutter.
                    if (!simplified) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 28, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
