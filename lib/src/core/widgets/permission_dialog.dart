import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';

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

  // Define all required permissions in order
  final List<RequiredPermission> _requiredPermissions = const [
    RequiredPermission(
      type: AppPermissionType.storage,
      title: 'Fayl saqlash ruxsati',
      description: 'Ilova ma\'lumotlarini saqlash va yuklash uchun',
      purpose: 'Rasmlar, hujjatlar va ma\'lumotlarni saqlash',
      isRequired: true,
    ),
    RequiredPermission(
      type: AppPermissionType.location,
      title: 'Joylashuv ruxsati',
      description: 'Savdo nuqtalarini masofaga ko\'ra tartiblash uchun',
      purpose: 'Xaritada joylashuvni ko\'rsatish va masofa hisoblash',
      isRequired: true,
    ),
    RequiredPermission(
      type: AppPermissionType.locationAlways,
      title: 'Doimiy joylashuv ruxsati',
      description: 'Ilova fon rejimida ishlaganda joylashuvni aniqlash uchun',
      purpose: 'Fon rejimida xizmat ko\'rsatish va bildirishnomalar',
      isRequired: true,
    ),
    RequiredPermission(
      type: AppPermissionType.camera,
      title: 'Kamera ruxsati',
      description: 'Rasmga olish va shtrix-kod skanerlash uchun',
      purpose: 'Mahsulotlar va savdo nuqtalarini rasmga olish',
      isRequired: true,
    ),
    RequiredPermission(
      type: AppPermissionType.microphone,
      title: 'Mikrofon ruxsati',
      description: 'Ovoz yozish va audio xabarlar uchun',
      purpose: 'Ovozli eslatmalar va audio qaydlar',
      isRequired: true,
    ),
    RequiredPermission(
      type: AppPermissionType.notification,
      title: 'Bildirishnoma ruxsati',
      description: 'Muhim xabarlarni ko\'rsatish uchun',
      purpose: 'Eslatmalar, yangiliklar va bildirishnomalar',
      isRequired: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentPermission();
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

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '${permission.title} kerak',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '${permission.description}. Iltimos, ilova sozlamalaridan ruxsat bering.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keyinroq'),
          ),
          FilledButton(
            onPressed: () async {
              await _permissionManager.openAppSettings();
              Navigator.of(context).pop(true);
            },
            child: const Text('Sozlamalarga o\'tish'),
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
              'Maqsad: ${permission.purpose}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ruxsat berishni xohlaysizmi?',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (!_isLoading) ...[
            TextButton(
              onPressed: _skipPermission,
              child: const Text('Keyinroq'),
            ),
            FilledButton(
              onPressed: _requestPermission,
              child: const Text('Ruxsat berish'),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Tekshirilmoqda...',
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

    return AlertDialog(
      title: Text(
        'Ruxsatlar tekshiruvi',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ilova to\'liq ishlashi uchun quyidagi ruxsatlar kerak:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildPermissionItem('Fayl saqlash', 'Ma\'lumotlarni saqlash'),
          _buildPermissionItem('Joylashuv', 'Xarita va masofa hisoblash'),
          _buildPermissionItem('Kamera', 'Rasmga olish'),
          _buildPermissionItem('Mikrofon', 'Ovoz yozish'),
          _buildPermissionItem('Bildirishnomalar', 'Xabarlarni ko\'rsatish'),
          const SizedBox(height: 12),
          Text(
            'Ruxsatlarsiz ilova cheklangan rejimda ishlaydi.',
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
          child: const Text('Boshlash'),
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