import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent, kind user feedback across MediAssist.
///
/// Note: the success helper takes a ScaffoldMessengerState (captured BEFORE any
/// navigation/await) so the confirmation still shows after a form screen pops —
/// and it avoids "context used after async gap" issues.

/// Show a success confirmation (green check) — e.g. after saving or deleting.
void showSuccessSnack(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF66E0A3), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 15))),
        ],
      ),
    ),
  );
}

/// A consistent, gentle confirmation dialog for important/destructive actions.
/// Returns true only if the user confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: const TextStyle(fontSize: 16)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : AppColors.teal,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
