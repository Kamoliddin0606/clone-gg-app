import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// Custom permission status enum
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown
}

/// Centralized permission manager for the application
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  /// Check location permission status
  Future<AppPermissionStatus> checkLocationPermission() async {
    final status = await Permission.location.status;
    return _mapToAppStatus(status);
  }

  /// Request location permission
  Future<AppPermissionStatus> requestLocationPermission() async {
    final status = await Permission.location.request();
    return _mapToAppStatus(status);
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Show location permission dialog with service check
  Future<bool> showLocationPermissionDialog(BuildContext context) async {
    // First check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationServiceDialog(),
      ) ?? false;
    }

    // Services are enabled, show permission dialog
    return await _showPermissionDialog(context);
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await checkLocationPermission();
    return status == AppPermissionStatus.granted;
  }

  /// Handle location permission for a specific feature
  Future<bool> ensureLocationPermissionForFeature(BuildContext context) async {
    final status = await checkLocationPermission();

    switch (status) {
      case AppPermissionStatus.granted:
        return true;

      case AppPermissionStatus.denied:
        return await _showPermissionDialog(context);

      case AppPermissionStatus.permanentlyDenied:
        await _showSettingsDialog(context);
        return false;

      default:
        // For unknown or restricted status, try to request permission
        return await _showPermissionDialog(context);
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location service status: $e');
      }
      return false;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening location settings: $e');
      }
      return false;
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationPermissionDialog(),
    );

    if (result == true) {
      final newStatus = await requestLocationPermission();
      return newStatus == AppPermissionStatus.granted;
    }

    return false;
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationSettingsDialog(),
    );
  }

  AppPermissionStatus _mapToAppStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      default:
        return AppPermissionStatus.unknown;
    }
  }
}

/// Location permission request dialog
class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Joylashuv ruxsati kerak',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Savdo nuqtalarini masofaga ko\'ra tartiblash va xaritada ko\'rsatish uchun '
        'sizning joylashuvingiz kerak. Ruxsat berasizmi?',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keyinroq'),
        ),
        FilledButton(
          onPressed: () async {
            // Request permission directly from OS
            final status = await Permission.location.request();
            final appStatus = PermissionManager()._mapToAppStatus(status);
            Navigator.of(context).pop(appStatus == AppPermissionStatus.granted);
          },
          child: const Text('Ruxsat berish'),
        ),
      ],
    );
  }
}

/// Settings redirect dialog for permanently denied permissions
class LocationSettingsDialog extends StatelessWidget {
  const LocationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Joylashuv ruxsati kerak',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Masofa bo\'yicha tartiblash va xarita funksiyalari uchun joylashuv ruxsati zarur. '
        'Iltimos, ilova sozlamalaridan joylashuv ruxsatini bering.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () async {
            await PermissionManager().openAppSettings();
            Navigator.of(context).pop();
          },
          child: const Text('Sozlamalarga o\'tish'),
        ),
      ],
    );
  }
}

/// Location service disabled dialog
class LocationServiceDialog extends StatelessWidget {
  const LocationServiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Joylashuv xizmatlari o\'chirilgan',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Masofa bo\'yicha tartiblash va xarita funksiyalari uchun joylashuv xizmatlari yoqilgan bo\'lishi kerak. '
        'Iltimos, joylashuv xizmatlarini yoqing.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keyinroq'),
        ),
        FilledButton(
          onPressed: () async {
            final permissionManager = PermissionManager();
            final opened = await permissionManager.openLocationSettings();
            Navigator.of(context).pop(opened);
          },
          child: const Text('Joylashuv sozlamalari'),
        ),
      ],
    );
  }
}