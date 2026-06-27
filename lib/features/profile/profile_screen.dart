import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../models/app_user.dart';

/// Shows the user's profile (name, email, role), lets them edit their name and
/// role, and log out. Uses a live stream so edits appear instantly.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: authService.watchCurrentUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data;
            if (user == null) {
              return const Center(
                child: Text('Could not load profile.', style: TextStyle(fontSize: 18)),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 44, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _infoCard(
                  icon: Icons.person,
                  label: 'Name',
                  value: user.name,
                  onEdit: () => _editName(context, authService, user.name),
                ),
                const SizedBox(height: 14),
                _infoCard(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email,
                ),
                const SizedBox(height: 14),
                _infoCard(
                  icon: user.role == UserRole.elderly ? Icons.elderly : Icons.favorite,
                  label: 'Role',
                  value: user.role == UserRole.elderly ? 'Elderly User' : 'Caregiver',
                  onEdit: () => _changeRole(context, authService, user.role),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 24, color: Colors.red),
                    label: const Text('Log Out',
                        style: TextStyle(fontSize: 18, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmLogout(context, authService),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.teal),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit', style: TextStyle(fontSize: 15)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, AuthService authService, String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name', style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 16))),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await authService.updateProfile(name: newName);
    }
  }

  Future<void> _changeRole(
      BuildContext context, AuthService authService, UserRole current) async {
    UserRole selected = current;
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role', style: TextStyle(fontSize: 20)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<UserRole>(
                  title: const Text('Elderly User', style: TextStyle(fontSize: 17)),
                  value: UserRole.elderly,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                ),
                RadioListTile<UserRole>(
                  title: const Text('Caregiver', style: TextStyle(fontSize: 17)),
                  value: UserRole.caregiver,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 16))),
          TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Save', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
    if (result != null && result != current) {
      await authService.updateProfile(role: result);
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?', style: TextStyle(fontSize: 20)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 16))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out',
                  style: TextStyle(fontSize: 16, color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await authService.logout();
      // The AuthGate switches to the login screen automatically; pop the pushed
      // screens so we don't leave Profile sitting on top of it.
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
