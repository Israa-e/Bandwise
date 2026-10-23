import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'empty_state_view.dart';
import 'session_top_bar.dart';

/// A full-screen message in a session: not found, or failed to load with
/// Retry. Has only the close button in the top bar.
class SessionMessageScaffold extends StatelessWidget {
  const SessionMessageScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return Scaffold(
      appBar: SessionTopBar(onClose: onBack, closeTooltip: 'Close practice'),
      body: EmptyStateView(
        icon: icon,
        title: title,
        message: message,
        action: Column(
          children: [
            if (onRetry != null) ...[
              AppButton.primary(
                label: 'Retry',
                expand: false,
                onPressed: onRetry,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton.outline(
              label: 'Go back',
              expand: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
