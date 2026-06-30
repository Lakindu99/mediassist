import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/adaptive_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        // Long-press the title to open the hidden researcher panel.
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('What would you like to do?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (adaptiveOn) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple),
                        SizedBox(width: 6),
                        Text('Adaptive Mode active',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _DashboardTile(
                icon: Icons.today,
                title: "Today's Plan",
                subtitle: 'See what is due today',
                color: Colors.deepOrange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TodayScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.medication,
                title: 'My Medications',
                subtitle: 'View and manage your medicines',
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MedicationListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.calendar_month,
                title: 'My Appointments',
                subtitle: 'View and manage your appointments',
                color: Colors.indigo,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.history,
                title: 'Medication History',
                subtitle: 'See doses you have taken',
                color: Colors.purple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdherenceHistoryScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _DashboardTile(
                icon: Icons.people,
                title: 'Caregiver',
                subtitle: 'Share access or monitor a loved one',
                color: Colors.brown,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CaregiverScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 15, color: Colors.black54)),
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
