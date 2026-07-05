import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_provider.dart';
import '../services/adaptive_engine.dart';

/// A large, high-contrast button for elderly users. In adaptive mode its
/// height/tap-target grows automatically when the engine detects mis-taps.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final adaptiveOn = context.watch<AdaptiveProvider>().adaptiveMode;
    final scale = adaptiveOn ? context.watch<AdaptiveEngine>().buttonScale : 1.0;
    return SizedBox(
      width: double.infinity,
      height: 60 * scale,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24, width: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 24), const SizedBox(width: 10)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// A large, clearly-labelled text field for elderly users.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 18),
        prefixIcon: Icon(icon, size: 26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}
