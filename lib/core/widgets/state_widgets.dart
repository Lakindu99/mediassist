import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A friendly, reassuring empty-state placeholder for elderly users.
/// Shows a soft icon, a clear message, and (optionally) a guiding action —
/// so a screen with no data never looks broken or confusing.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.teal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: color),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A consistent loading indicator with a short message, so a loading screen
/// never looks blank or frozen.
class LoadingState extends StatelessWidget {
  final String message;
  const LoadingState({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        ],
      ),
    );
  }
}
