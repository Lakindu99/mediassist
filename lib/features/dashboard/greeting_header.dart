import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../models/app_user.dart';

/// A warm, personalised greeting at the top of the dashboard, to help the user
/// feel oriented and welcomed ("Good morning, Nimal"). Falls back to a plain
/// greeting if the name isn't available yet.
class GreetingHeader extends StatefulWidget {
  const GreetingHeader({super.key});
  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final AppUser? user = await auth.getCurrentUserProfile();
    if (!mounted) return;
    final name = user?.name.trim();
    setState(() {
      _firstName =
          (name != null && name.isNotEmpty) ? name.split(' ').first : null;
    });
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting =
        _firstName != null ? '${_timeGreeting()}, $_firstName' : _timeGreeting();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('What would you like to do?',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
}
