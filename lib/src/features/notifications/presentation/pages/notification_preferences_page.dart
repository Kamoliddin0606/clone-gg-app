import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/notification_preferences.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnoma sozlamalari'),
      ),
      body: StreamBuilder<NotificationPreferences>(
        stream: service.stream,
        initialData: service.value,
        builder: (context, snapshot) {
          final prefs = snapshot.data ?? NotificationPreferences.defaults;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _SectionHeader('Bildirishnoma turlari'),
              ...NotificationTypes.all.map(
                (type) => _TypeToggleTile(
                  type: type,
                  enabled: prefs.isTypeEnabled(type),
                  onChanged: (v) =>
                      service.update(prefs.withTypeEnabled(type, v)),
                ),
              ),
              const Divider(height: 32),
              _SectionHeader('Bezovta qilmang (DND)'),
              _DndTile(
                prefs: prefs,
                onChanged: (next) => service.update(next),
              ),
              const Divider(height: 32),
              _SectionHeader('Tovush va tebranish'),
              for (final priority in const ['urgent', 'high', 'normal', 'low'])
                _SoundLevelTile(
                  priority: priority,
                  level: prefs.soundFor(priority),
                  onChanged: (level) => service.update(
                    prefs.withSoundForPriority(priority, level),
                  ),
                ),
            ],
          );
        },
      ),
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
    return SwitchListTile(
      title: Text(_labelFor(type)),
      subtitle: Text(_descriptionFor(type)),
      value: enabled,
      onChanged: onChanged,
      secondary: Icon(_iconFor(type)),
    );
  }

  String _labelFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return 'Qarz ogohlantirishlari';
      case NotificationTypes.orderNew:
        return 'Yangi buyurtmalar';
      case NotificationTypes.stockLotExpiring:
        return 'Lot tugashi';
      case NotificationTypes.systemAnnouncement:
        return 'Tizim e\'lonlari';
      default:
        return type;
    }
  }

  String _descriptionFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return 'Mijoz qarzlari haqida bildirishnomalar';
      case NotificationTypes.orderNew:
        return 'Yangi buyurtma haqida ogohlantirish';
      case NotificationTypes.stockLotExpiring:
        return 'Ombor lotining muddati tugashi';
      case NotificationTypes.systemAnnouncement:
        return 'Tizim va boshqaruv yangiliklari';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Bezovta qilmang'),
          subtitle: Text(
            prefs.isDndEnabled
                ? '${_fmt(prefs.dndStart!)} – ${_fmt(prefs.dndEnd!)}'
                : 'Belgilangan vaqt ichida banner ko\'rsatilmaydi',
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
                    label: 'Boshlanish',
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
                    label: 'Tugash',
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
    return ListTile(
      leading: Icon(_iconFor(priority)),
      title: Text(_labelFor(priority)),
      trailing: DropdownButton<NotificationSoundLevel>(
        value: level,
        underline: const SizedBox.shrink(),
        items: NotificationSoundLevel.values
            .map(
              (l) => DropdownMenuItem<NotificationSoundLevel>(
                value: l,
                child: Text(_levelLabel(l)),
              ),
            )
            .toList(),
        onChanged: (l) {
          if (l != null) onChanged(l);
        },
      ),
    );
  }

  String _labelFor(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Shoshilinch';
      case 'high':
        return 'Yuqori';
      case 'low':
        return 'Past';
      case 'normal':
      default:
        return 'Oddiy';
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

  String _levelLabel(NotificationSoundLevel l) {
    switch (l) {
      case NotificationSoundLevel.silent:
        return 'Jim';
      case NotificationSoundLevel.vibrate:
        return 'Tebranish';
      case NotificationSoundLevel.sound:
        return 'Tovush';
    }
  }
}
