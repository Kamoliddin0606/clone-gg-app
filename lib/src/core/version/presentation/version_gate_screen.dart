import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_service.dart';

/// Full-screen, non-dismissable block surface shown when the backend gate
/// returns `force_update`, `blocked`, or `maintenance`.
///
/// Three knobs vary by status:
///   - icon / accent
///   - primary CTA (store launcher vs. retry vs. exit)
///   - title + message text (server-driven; falls back to localized strings
///     when the backend payload's `title`/`message` are empty)
class VersionGateScreen extends StatefulWidget {
  final VersionGateResponse payload;
  final Future<VersionGateResponse?> Function()? onRetry;

  const VersionGateScreen({
    super.key,
    required this.payload,
    this.onRetry,
  });

  @override
  State<VersionGateScreen> createState() => _VersionGateScreenState();
}

class _VersionGateScreenState extends State<VersionGateScreen> {
  late VersionGateResponse _payload;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  Future<void> _launchStore() async {
    final raw = _payload.storeUrl.trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently — the screen stays put; user can re-tap or close the app.
    }
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      VersionGateResponse? next;
      if (widget.onRetry != null) {
        next = await widget.onRetry!();
      } else {
        final service = _maybeService();
        if (service != null) {
          next = await service.checkOnStartup();
        }
      }
      if (!mounted) return;
      if (next != null) {
        if (!next.status.blocksApp) {
          // Backend cleared the gate — drop the screen.
          Navigator.of(context).pop();
          return;
        }
        setState(() => _payload = next!);
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  VersionGateService? _maybeService() {
    try {
      if (sl.isRegistered<VersionGateService>()) {
        return sl<VersionGateService>();
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isMaintenance = _payload.status == VersionGateStatus.maintenance;
    final title = _payload.title.isNotEmpty
        ? _payload.title
        : _fallbackTitle(l10n, _payload.status);
    final message = _payload.message.isNotEmpty
        ? _payload.message
        : _fallbackMessage(l10n, _payload.status);

    final primaryLabel = isMaintenance
        ? (l10n?.versionGate_retryButton ?? 'Qaytadan urinish')
        : (l10n?.versionGate_updateButton ?? 'Yangilash');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _iconFor(_payload.status),
                      size: 96,
                      color: _accentFor(theme, _payload.status),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_payload.releaseNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _payload.releaseNotes.trim(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    if (_payload.latestVersion.isNotEmpty &&
                        _payload.currentVersion.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${_payload.currentVersion} → ${_payload.latestVersion}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _retrying
                            ? null
                            : (isMaintenance ? _retry : _launchStore),
                        icon: _retrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isMaintenance
                                    ? Icons.refresh
                                    : Icons.system_update_alt,
                              ),
                        label: Text(primaryLabel),
                      ),
                    ),
                    if (_payload.status == VersionGateStatus.blocked ||
                        _payload.status == VersionGateStatus.forceUpdate)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextButton(
                          onPressed: () => SystemNavigator.pop(),
                          child: Text(
                            l10n?.versionGate_exitButton ?? 'Ilovadan chiqish',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(VersionGateStatus status) {
    switch (status) {
      case VersionGateStatus.forceUpdate:
      case VersionGateStatus.softUpdate:
        return Icons.system_update_alt;
      case VersionGateStatus.blocked:
        return Icons.shield_outlined;
      case VersionGateStatus.maintenance:
        return Icons.build_circle_outlined;
      case VersionGateStatus.ok:
        return Icons.check_circle_outline;
    }
  }

  static Color _accentFor(ThemeData theme, VersionGateStatus status) {
    switch (status) {
      case VersionGateStatus.blocked:
        return theme.colorScheme.error;
      case VersionGateStatus.maintenance:
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _fallbackTitle(
    AppLocalizations? l10n,
    VersionGateStatus status,
  ) {
    switch (status) {
      case VersionGateStatus.forceUpdate:
        return l10n?.versionGate_forceUpdate_title ?? 'Yangilanish majburiy';
      case VersionGateStatus.softUpdate:
        return l10n?.versionGate_softUpdate_title ?? 'Yangilanish mavjud';
      case VersionGateStatus.blocked:
        return l10n?.versionGate_blocked_title ?? 'Ushbu versiya bloklangan';
      case VersionGateStatus.maintenance:
        return l10n?.versionGate_maintenance_title ?? 'Texnik ishlar';
      case VersionGateStatus.ok:
        return '';
    }
  }

  static String _fallbackMessage(
    AppLocalizations? l10n,
    VersionGateStatus status,
  ) {
    switch (status) {
      case VersionGateStatus.forceUpdate:
        return l10n?.versionGate_forceUpdate_message ??
            'Ishlashda davom etish uchun yangilang.';
      case VersionGateStatus.softUpdate:
        return l10n?.versionGate_softUpdate_message ??
            'Ilovaning yangi versiyasi chiqdi.';
      case VersionGateStatus.blocked:
        return l10n?.versionGate_blocked_message ??
            'Ilovaning yangi versiyasini yuklab oling.';
      case VersionGateStatus.maintenance:
        return l10n?.versionGate_maintenance_message ??
            'Server vaqtinchalik ishlamayapti.';
      case VersionGateStatus.ok:
        return '';
    }
  }
}
