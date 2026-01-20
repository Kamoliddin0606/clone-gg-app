import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Dialog shown when offline access is blocked (first-time user without internet)
/// 
/// Material Design 3 compliant with:
/// - Info visual hierarchy
/// - Friendly explanation
/// - Single action button
class OfflineAccessBlockedDialog extends StatelessWidget {
  final VoidCallback onConnectToInternet;

  const OfflineAccessBlockedDialog({
    super.key,
    required this.onConnectToInternet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.wifi_off_rounded,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        l10n?.offlineAccessBlocked ?? 'Internet Connection Required',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.offlineAccessBlockedMessage ?? 
                'First-time access requires an internet connection. Please connect and try again.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.offlineAccessBlockedNote ?? 
                        'After first connection, you can use the app offline.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: onConnectToInternet,
          icon: const Icon(Icons.wifi),
          label: Text(l10n?.connectToInternet ?? 'Connect to Internet'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}
