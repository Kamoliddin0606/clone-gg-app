import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/notification_preferences.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/fcm_token_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';

/// Phase 2 §1 — Notification preferences screen.
///
/// Reachable from the notification list AppBar (gear icon). Listens on
/// [NotificationPreferencesService.stream] so toggles applied
/// elsewhere stay in sync; writes go through `update()` which persists
/// and rebroadcasts.
class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = sl<NotificationPreferencesService>();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notif_prefsTitle),
      ),
      body: StreamBuilder<NotificationPreferences>(
        stream: service.stream,
        initialData: service.value,
        builder: (context, snapshot) {
          final prefs = snapshot.data ?? NotificationPreferences.defaults;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _SectionHeader(l10n.notif_prefsSection_types),
              ...NotificationTypes.all.map(
                (type) => _TypeToggleTile(
                  type: type,
                  enabled: prefs.isTypeEnabled(type),
                  onChanged: (v) =>
                      service.update(prefs.withTypeEnabled(type, v)),
                ),
              ),
              const Divider(height: 32),
              _SectionHeader(l10n.notif_prefsSection_dnd),
              _DndTile(
                prefs: prefs,
                onChanged: (next) => service.update(next),
              ),
              const Divider(height: 32),
              _SectionHeader(l10n.notif_prefsSection_sound),
              for (final priority in const ['urgent', 'high', 'normal', 'low'])
                _SoundLevelTile(
                  priority: priority,
                  level: prefs.soundFor(priority),
                  onChanged: (level) => service.update(
                    prefs.withSoundForPriority(priority, level),
                  ),
                ),
              const Divider(height: 32),
              const _SectionHeader('Diagnostika'),
              const _FcmTokenTile(),
              const _PendingReadsTile(),
            ],
          );
        },
      ),
    );
  }
}

/// Phase 2 diagnostic — surface the offline mark-read queue. A
/// non-zero count means at least one `markRead` HTTP call failed and
/// the id is waiting for the next bulk-read flush. Useful when the
/// backend isn't recording reads even though the row looks read
/// locally.
class _PendingReadsTile extends StatefulWidget {
  const _PendingReadsTile();

  @override
  State<_PendingReadsTile> createState() => _PendingReadsTileState();
}

class _PendingReadsTileState extends State<_PendingReadsTile> {
  int? _count;
  bool _flushing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await sl<NotificationRepository>().pendingReadCount();
    if (!mounted) return;
    setState(() => _count = count);
  }

  Future<void> _flush() async {
    if (_flushing) return;
    setState(() => _flushing = true);
    final messenger = ScaffoldMessenger.of(context);
    final flushed = await sl<NotificationRepository>().flushPendingReads();
    if (!mounted) return;
    setState(() => _flushing = false);
    await _refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(flushed > 0
            ? '$flushed ta o\'qilgan belgisi jo\'natildi'
            : 'Jo\'natish muvaffaqiyatsiz — internet yoki backend muammosi'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return ListTile(
      leading: const Icon(Icons.sync_problem_outlined),
      title: const Text('Yuborilmagan "o\'qildi" belgilari'),
      subtitle: Text(
        count == null
            ? 'Yuklanmoqda…'
            : count == 0
                ? 'Hammasi backend\'ga yetkazilgan'
                : '$count ta belgisi jo\'natishni kutmoqda',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _flushing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Hoziroq jo\'natish',
            onPressed: (count == null || count == 0 || _flushing) ? null : _flush,
            icon: _flushing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}

/// Phase 2 diagnostic — copy the device's current FCM token to the
/// clipboard. Useful for backend-side troubleshooting: paste the
/// token into Firebase Console → Cloud Messaging → "Test on device"
/// to verify the FCM↔device path independent of the backend.
class _FcmTokenTile extends StatefulWidget {
  const _FcmTokenTile();

  @override
  State<_FcmTokenTile> createState() => _FcmTokenTileState();
}

class _FcmTokenTileState extends State<_FcmTokenTile> {
  String? _token;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final token = await sl<FcmTokenService>().fetchCurrentToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _loading = false;
    });
  }

  String _preview(String token) {
    if (token.length <= 24) return token;
    return '${token.substring(0, 12)}…${token.substring(token.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.vpn_key_outlined),
          title: const Text('FCM token'),
          subtitle: _loading
              ? const Text('Yuklanmoqda…')
              : Text(
                  _token == null
                      ? 'Token mavjud emas (ruxsat berilmagan bo\'lishi mumkin)'
                      : _preview(_token!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Yangilash',
                onPressed: _loading ? null : _fetch,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Nusxalash',
                onPressed: _token == null
                    ? null
                    : () async {
                        // Capture the messenger BEFORE the async gap
                        // so we never touch a stale context after
                        // the clipboard call returns.
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: _token!));
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('FCM token nusxalandi'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypeToggleTile extends StatelessWidget {
  final String type;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TypeToggleTile({
    required this.type,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      title: Text(_labelFor(l10n, type)),
      subtitle: Text(_descriptionFor(l10n, type)),
      value: enabled,
      onChanged: onChanged,
      secondary: Icon(_iconFor(type)),
    );
  }

  String _labelFor(AppLocalizations l10n, String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return l10n.notif_type_debtAlert;
      case NotificationTypes.orderNew:
        return l10n.notif_type_orderNew;
      case NotificationTypes.stockLotExpiring:
        return l10n.notif_type_stockLotExpiring;
      case NotificationTypes.systemAnnouncement:
        return l10n.notif_type_systemAnnouncement;
      default:
        return type;
    }
  }

  String _descriptionFor(AppLocalizations l10n, String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return l10n.notif_typeDesc_debtAlert;
      case NotificationTypes.orderNew:
        return l10n.notif_typeDesc_orderNew;
      case NotificationTypes.stockLotExpiring:
        return l10n.notif_typeDesc_stockLotExpiring;
      case NotificationTypes.systemAnnouncement:
        return l10n.notif_typeDesc_systemAnnouncement;
      default:
        return '';
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return Icons.warning_amber_rounded;
      case NotificationTypes.orderNew:
        return Icons.receipt_long;
      case NotificationTypes.stockLotExpiring:
        return Icons.inventory_2;
      case NotificationTypes.systemAnnouncement:
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}

class _DndTile extends StatelessWidget {
  final NotificationPreferences prefs;
  final ValueChanged<NotificationPreferences> onChanged;

  const _DndTile({required this.prefs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(l10n.notif_dnd_toggleTitle),
          subtitle: Text(
            prefs.isDndEnabled
                ? '${_fmt(prefs.dndStart!)} – ${_fmt(prefs.dndEnd!)}'
                : l10n.notif_dnd_hint,
          ),
          value: prefs.isDndEnabled,
          onChanged: (v) {
            if (v) {
              onChanged(prefs.copyWith(
                dndStart: const TimeOfDay(hour: 22, minute: 0),
                dndEnd: const TimeOfDay(hour: 7, minute: 0),
              ));
            } else {
              onChanged(prefs.copyWith(clearDnd: true));
            }
          },
          secondary: const Icon(Icons.bedtime_outlined),
        ),
        if (prefs.isDndEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: l10n.notif_dnd_startLabel,
                    value: prefs.dndStart!,
                    onChanged: (t) => onChanged(prefs.copyWith(dndStart: t)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                      color: theme.colorScheme.outline),
                ),
                Expanded(
                  child: _TimeButton(
                    label: l10n.notif_dnd_endLabel,
                    value: prefs.dndEnd!,
                    onChanged: (t) => onChanged(prefs.copyWith(dndEnd: t)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onChanged(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SoundLevelTile extends StatelessWidget {
  final String priority;
  final NotificationSoundLevel level;
  final ValueChanged<NotificationSoundLevel> onChanged;

  const _SoundLevelTile({
    required this.priority,
    required this.level,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Icon(_iconFor(priority)),
      title: Text(_labelFor(l10n, priority)),
      trailing: DropdownButton<NotificationSoundLevel>(
        value: level,
        underline: const SizedBox.shrink(),
        items: NotificationSoundLevel.values
            .map(
              (l) => DropdownMenuItem<NotificationSoundLevel>(
                value: l,
                child: Text(_levelLabel(l10n, l)),
              ),
            )
            .toList(),
        onChanged: (l) {
          if (l != null) onChanged(l);
        },
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, String priority) {
    switch (priority) {
      case 'urgent':
        return l10n.notif_priority_urgent;
      case 'high':
        return l10n.notif_priority_high;
      case 'low':
        return l10n.notif_priority_low;
      case 'normal':
      default:
        return l10n.notif_priority_normal;
    }
  }

  IconData _iconFor(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.notifications_active;
      case 'low':
        return Icons.notifications_none;
      case 'normal':
      default:
        return Icons.notifications;
    }
  }

  String _levelLabel(AppLocalizations l10n, NotificationSoundLevel l) {
    switch (l) {
      case NotificationSoundLevel.silent:
        return l10n.notif_sound_silent;
      case NotificationSoundLevel.vibrate:
        return l10n.notif_sound_vibrate;
      case NotificationSoundLevel.sound:
        return l10n.notif_sound_sound;
    }
  }
}
