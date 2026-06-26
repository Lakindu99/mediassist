import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';

/// Temporary home shown after login. Confirms login works and offers logout.
/// We'll build the real dashboard (medications, appointments) on top of this.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final email = authService.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediAssist', style: TextStyle(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 26),
            tooltip: 'Log out',
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 90, color: Colors.teal),
              const SizedBox(height: 20),
              const Text('You are logged in!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(email, style: const TextStyle(fontSize: 18, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
