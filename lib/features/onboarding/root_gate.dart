import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_gate.dart';
import 'onboarding_screen.dart';

/// Shows the onboarding walkthrough on first launch only, then hands over to
/// the normal AuthGate. The "seen" flag is stored on the device.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool? _seen; // null = still loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _seen = prefs.getBool('onboardingSeen') ?? false);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
    if (mounted) setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) return const Scaffold(body: SizedBox()); // brief, no flicker
    if (_seen == false) return OnboardingScreen(onDone: _complete);
    return const AuthGate();
  }
}