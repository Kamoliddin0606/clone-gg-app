import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_service.dart';

/// Dismissable soft-update dialog. Shown when the splash check returns
/// `soft_update` and the dismiss-window has not been opened in the last 24h.
///
/// Returns `true` if the user tapped "Yangilash" (and the store launch was
/// attempted), `false` if they tapped "Keyinroq" or dismissed via barrier.
Future<bool?> showUpdateAvailableDialog(
  BuildContext context, {
  required VersionGateResponse payload,
  required VersionGateService service,
}) {
  final l10n = AppLocalizations.of(context);
  final fallbackTitle = l10n?.versionGate_softUpdate_title ?? 'Yangilanish mavjud';
  final fallbackMessage =
      l10n?.versionGate_softUpdate_message ?? 'Ilovaning yangi versiyasi chiqdi.';
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      final theme = Theme.of(dialogCtx);
      return AlertDialog(
        title: Text(
          payload.title.isNotEmpty ? payload.title : fallbackTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                payload.message.isNotEmpty
                    ? payload.message
                    : fallbackMessage,
              ),
              if (payload.releaseNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  payload.releaseNotes.trim(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (payload.latestVersion.isNotEmpty &&
                  payload.currentVersion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${payload.currentVersion} → ${payload.latestVersion}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await service.dismissSoftUpdate();
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop(false);
              }
            },
            child: Text(
              l10n?.versionGate_laterButton ?? 'Keyinroq',
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.system_update_alt, size: 18),
            onPressed: () async {
              final raw = payload.storeUrl.trim();
              if (raw.isNotEmpty) {
                final uri = Uri.tryParse(raw);
                if (uri != null) {
                  try {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                }
              }
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop(true);
              }
            },
            label: Text(
              l10n?.versionGate_updateButton ?? 'Yangilash',
            ),
          ),
        ],
      );
    },
  );
}
