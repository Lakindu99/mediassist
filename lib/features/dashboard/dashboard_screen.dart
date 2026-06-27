import 'package:flutter/material.dart';
import '../today/today_screen.dart';
import '../medication/medication_list_screen.dart';
import '../appointment/appointment_list_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediAssist', style: TextStyle(fontSize: 22)),
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
