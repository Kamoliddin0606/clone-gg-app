import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Dialog shown when user's time limit has expired
/// 
/// Material Design 3 compliant with:
/// - Warning visual hierarchy
/// - Clear messaging
/// - Action buttons for user response
class TimeLimitExpiredDialog extends StatelessWidget {
  final VoidCallback onContactSupport;
  final VoidCallback onRetry;

  const TimeLimitExpiredDialog({
    super.key,
    required this.onContactSupport,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: Text(
        l10n?.timeLimitExpired ?? 'Access Period Expired',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.timeLimitExpiredMessage ?? 
                'Your access period has expired. Please contact support to renew your access.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.timeLimitExpiredNote ?? 
                        'All local data will be cleared for security.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: Text(l10n?.retryConnection ?? 'Retry Connection'),
        ),
        FilledButton(
          onPressed: onContactSupport,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(l10n?.contactSupport ?? 'Contact Support'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}
