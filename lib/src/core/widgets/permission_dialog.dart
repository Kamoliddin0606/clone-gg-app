import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Data class for required permissions
class RequiredPermission {
  final AppPermissionType type;
  final String title;
  final String description;
  final String purpose;
  final bool isRequired;

  const RequiredPermission({
    required this.type,
    required this.title,
    required this.description,
    required this.purpose,
    this.isRequired = true,
  });
}

/// Comprehensive permission dialog that checks permissions sequentially
class ComprehensivePermissionDialog extends StatefulWidget {
  const ComprehensivePermissionDialog({super.key});

  @override
  State<ComprehensivePermissionDialog> createState() => _ComprehensivePermissionDialogState();
}

class _ComprehensivePermissionDialogState extends State<ComprehensivePermissionDialog> {
  final PermissionManager _permissionManager = PermissionManager();
  int _currentPermissionIndex = 0;
  bool _isLoading = false;
  List<RequiredPermission> _requiredPermissions = [];

  Future<void> _loadPermissions() async {
    final isAndroid13OrHigher = Platform.isAndroid ? await _isAndroid13OrHigher() : false;
    final l10n = AppLocalizations.of(context);

    _requiredPermissions = [
      RequiredPermission(
        type: AppPermissionType.storage,
        title: l10n?.permissionStorageTitle ?? 'Fayl saqlash ruxsati',
        description: isAndroid13OrHigher
            ? (l10n?.permissionStorageDescAndroid13 ?? 'Ilova ma\'lumotlarini saqlash uchun papka tanlash')
            : (l10n?.permissionStorageDescOther ?? 'Ilova ma\'lumotlarini saqlash va yuklash uchun'),
        purpose: isAndroid13OrHigher
            ? (l10n?.permissionStoragePurposeAndroid13 ?? 'Rasmlar, hujjatlar va ma\'lumotlarni saqlash uchun papka tanlang')
            : (l10n?.permissionStoragePurposeOther ?? 'Rasmlar, hujjatlar va ma\'lumotlarni saqlash'),
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.location,
        title: l10n?.permissionLocationTitle ?? 'Joylashuv ruxsati',
        description: l10n?.permissionLocationDescription ?? 'Savdo nuqtalarini masofaga ko\'ra tartiblash uchun',
        purpose: l10n?.permissionLocationPurpose ?? 'Xaritada joylashuvni ko\'rsatish va masofa hisoblash',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.locationAlways,
        title: l10n?.permissionLocationAlwaysTitle ?? 'Doimiy joylashuv ruxsati',
        description: l10n?.permissionLocationAlwaysDescription ?? 'Ilova fon rejimida ishlaganda joylashuvni aniqlash uchun',
        purpose: l10n?.permissionLocationAlwaysPurpose ?? 'Fon rejimida xizmat ko\'rsatish va bildirishnomalar',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.camera,
        title: l10n?.permissionCameraTitle ?? 'Kamera ruxsati',
        description: l10n?.permissionCameraDescription ?? 'Rasmga olish va shtrix-kod skanerlash uchun',
        purpose: l10n?.permissionCameraPurpose ?? 'Mahsulotlar va savdo nuqtalarini rasmga olish',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.microphone,
        title: l10n?.permissionMicrophoneTitle ?? 'Mikrofon ruxsati',
        description: l10n?.permissionMicrophoneDescription ?? 'Ovoz yozish va audio xabarlar uchun',
        purpose: l10n?.permissionMicrophonePurpose ?? 'Ovozli eslatmalar va audio qaydlar',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.notification,
        title: l10n?.permissionNotificationTitle ?? 'Bildirishnoma ruxsati',
        description: l10n?.permissionNotificationDescription ?? 'Muhim xabarlarni ko\'rsatish uchun',
        purpose: l10n?.permissionNotificationPurpose ?? 'Eslatmalar, yangiliklar va bildirishnomalar',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.audio,
        title: l10n?.permissionAudioTitle ?? 'Musiqa va audio ruxsati',
        description: l10n?.permissionAudioDescription ?? 'Audio fayllar bilan ishlash uchun',
        purpose: l10n?.permissionAudioPurpose ?? 'Musiqa, audio xabarlar va ovozli fayllar bilan ishlash',
        isRequired: true,
      ),
      RequiredPermission(
        type: AppPermissionType.photosAndVideos,
        title: l10n?.permissionPhotosVideosTitle ?? 'Rasmlar va videolar ruxsati',
        description: l10n?.permissionPhotosVideosDescription ?? 'Media fayllar bilan ishlash uchun',
        purpose: l10n?.permissionPhotosVideosPurpose ?? 'Rasmlar, videolar va media fayllar bilan ishlash',
        isRequired: true,
      ),
    ];
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPermissions().then((_) {
      if (mounted) {
        setState(() {});
        _checkCurrentPermission();
      }
    });
  }

  Future<void> _checkCurrentPermission() async {
    if (_currentPermissionIndex >= _requiredPermissions.length) {
      // All permissions checked, close dialog
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final permission = _requiredPermissions[_currentPermissionIndex];
      final status = await _permissionManager.checkPermission(permission.type);

      if (kDebugMode) {
        print('Permission check for ${permission.type}: $status');
      }

      if (status == AppPermissionStatus.granted) {
        // Permission already granted, move to next
        _moveToNextPermission();
      } else {
        // Permission not granted, show request dialog
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permission: $e');
      }
      // On error, move to next permission
      _moveToNextPermission();
    }
  }

  void _moveToNextPermission() {
    setState(() {
      _currentPermissionIndex++;
      _isLoading = false;
    });
    // Check next permission after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentPermission();
    });
  }

  Future<void> _requestPermission() async {
    if (_currentPermissionIndex >= _requiredPermissions.length) return;

    setState(() => _isLoading = true);

    try {
      final permission = _requiredPermissions[_currentPermissionIndex];
      final status = await _permissionManager.requestPermission(permission.type);

      if (kDebugMode) {
        print('Permission request for ${permission.type}: $status');
      }

      if (status == AppPermissionStatus.granted) {
        // Permission granted, move to next
        _moveToNextPermission();
      } else if (status == AppPermissionStatus.permanentlyDenied) {
        // Show settings dialog
        await _showSettingsDialog();
      } else {
        // Permission denied but not permanently, allow skip
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permission: $e');
      }
      // On error, allow skip
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSettingsDialog() async {
    final permission = _requiredPermissions[_currentPermissionIndex];
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.permissionRequired(permission.title) ?? '${permission.title} kerak',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n?.permissionRequiredSettings(permission.description) ?? '${permission.description}. Iltimos, ilova sozlamalaridan ruxsat bering.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.laterButton ?? 'Keyinroq'),
          ),
          FilledButton(
            onPressed: () async {
              await _permissionManager.openAppSettings();
              Navigator.of(context).pop(true);
            },
            child: Text(l10n?.goToSettings ?? 'Sozlamalarga o\'tish'),
          ),
        ],
      ),
    );

    if (result == true) {
      // User went to settings, recheck permission after delay
      await Future.delayed(const Duration(seconds: 2));
      _checkCurrentPermission();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _skipPermission() {
    if (kDebugMode) {
      print('Skipping permission: ${_requiredPermissions[_currentPermissionIndex].type}');
    }
    _moveToNextPermission();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPermissionIndex >= _requiredPermissions.length) {
      return const SizedBox.shrink();
    }

    final permission = _requiredPermissions[_currentPermissionIndex];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: AlertDialog(
        title: Text(
          permission.title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permission.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.permissionPurpose(permission.purpose) ?? 'Maqsad: ${permission.purpose}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.allowPermissionQuestion ?? 'Ruxsat berishni xohlaysizmi?',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (!_isLoading) ...[
            TextButton(
              onPressed: _skipPermission,
              child: Text(l10n?.later ?? 'Keyinroq'),
            ),
            FilledButton(
              onPressed: _requestPermission,
              child: Text(l10n?.grantPermission ?? 'Ruxsat berish'),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              l10n?.checking ?? 'Tekshirilmoqda...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Initial warning dialog shown before permission checks
class PermissionWarningDialog extends StatelessWidget {
  const PermissionWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        l10n?.permissionsCheckTitle ?? 'Ruxsatlar tekshiruvi',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.permissionsCheckDescription ?? 'Ilova to\'liq ishlashi uchun quyidagi ruxsatlar kerak:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildPermissionItem(
            l10n?.permissionFileStorage ?? 'Fayl saqlash',
            l10n?.permissionFileStorageDesc ?? 'Ma\'lumotlarni saqlash',
          ),
          _buildPermissionItem(
            l10n?.permissionLocation ?? 'Joylashuv',
            l10n?.permissionLocationDesc ?? 'Xarita va masofa hisoblash',
          ),
          _buildPermissionItem(
            l10n?.permissionCamera ?? 'Kamera',
            l10n?.permissionCameraDesc ?? 'Rasmga olish',
          ),
          _buildPermissionItem(
            l10n?.permissionMicrophone ?? 'Mikrofon',
            l10n?.permissionMicrophoneDesc ?? 'Ovoz yozish',
          ),
          _buildPermissionItem(
            l10n?.permissionNotifications ?? 'Bildirishnomalar',
            l10n?.permissionNotificationsDesc ?? 'Xabarlarni ko\'rsatish',
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.permissionsLimitedWarning ?? 'Ruxsatlarsiz ilova cheklangan rejimda ishlaydi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n?.startButton ?? 'Boshlash'),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}