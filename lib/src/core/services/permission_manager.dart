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

/// Permission types for the app
enum AppPermissionType {
  storage,
  location,
  locationAlways,
  camera,
  microphone,
  notification,
}

/// Centralized permission manager for the application
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  /// Check location permission status
  Future<AppPermissionStatus> checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapGeolocatorToAppStatus(permission);
  }

  /// Request location permission
  Future<AppPermissionStatus> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapGeolocatorToAppStatus(permission);
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check storage permission status
  Future<AppPermissionStatus> checkStoragePermission() async {
    try {
      final status = await Permission.storage.status;
      if (kDebugMode) {
        print('PermissionManager: Storage permission status: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking storage permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request storage permission
  Future<AppPermissionStatus> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      if (kDebugMode) {
        print('PermissionManager: Storage permission request result: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting storage permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Check camera permission status
  Future<AppPermissionStatus> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (kDebugMode) {
        print('PermissionManager: Camera permission status: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking camera permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request camera permission
  Future<AppPermissionStatus> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (kDebugMode) {
        print('PermissionManager: Camera permission request result: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting camera permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Check microphone permission status
  Future<AppPermissionStatus> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (kDebugMode) {
        print('PermissionManager: Microphone permission status: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking microphone permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request microphone permission
  Future<AppPermissionStatus> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (kDebugMode) {
        print('PermissionManager: Microphone permission request result: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting microphone permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Check notification permission status
  Future<AppPermissionStatus> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (kDebugMode) {
        print('PermissionManager: Notification permission status: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking notification permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request notification permission
  Future<AppPermissionStatus> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (kDebugMode) {
        print('PermissionManager: Notification permission request result: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting notification permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Check background location permission status
  Future<AppPermissionStatus> checkBackgroundLocationPermission() async {
    try {
      final status = await Permission.locationAlways.status;
      if (kDebugMode) {
        print('PermissionManager: Background location permission status: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking background location permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request background location permission
  Future<AppPermissionStatus> requestBackgroundLocationPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      if (kDebugMode) {
        print('PermissionManager: Background location permission request result: $status');
      }
      return _mapToAppStatus(status);
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting background location permission: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Check permission status for a specific type
  Future<AppPermissionStatus> checkPermission(AppPermissionType type) async {
    try {
      if (kDebugMode) {
        print('PermissionManager: Checking permission for type: $type');
      }
      switch (type) {
        case AppPermissionType.storage:
          return await checkStoragePermission();
        case AppPermissionType.location:
          return await checkLocationPermission();
        case AppPermissionType.locationAlways:
          return await checkBackgroundLocationPermission();
        case AppPermissionType.camera:
          return await checkCameraPermission();
        case AppPermissionType.microphone:
          return await checkMicrophonePermission();
        case AppPermissionType.notification:
          return await checkNotificationPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error checking permission for type $type: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Request permission for a specific type
  Future<AppPermissionStatus> requestPermission(AppPermissionType type) async {
    try {
      if (kDebugMode) {
        print('PermissionManager: Requesting permission for type: $type');
      }
      switch (type) {
        case AppPermissionType.storage:
          return await requestStoragePermission();
        case AppPermissionType.location:
          return await requestLocationPermission();
        case AppPermissionType.locationAlways:
          return await requestBackgroundLocationPermission();
        case AppPermissionType.camera:
          return await requestCameraPermission();
        case AppPermissionType.microphone:
          return await requestMicrophonePermission();
        case AppPermissionType.notification:
          return await requestNotificationPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        print('PermissionManager: Error requesting permission for type $type: $e');
      }
      return AppPermissionStatus.unknown;
    }
  }

  /// Show location permission dialog with service check
  Future<bool> showLocationPermissionDialog(BuildContext context) async {
    // First check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('servis enabled');
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationServiceDialog(),
      ) ?? false;
    }
    print('servis not enabled');
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
        print('Error checking location service status with Geolocator: $e');
      }
      // Fallback to permission_handler
      try {
        final serviceStatus = await Permission.location.serviceStatus;
        return serviceStatus.isEnabled;
      } catch (e2) {
        if (kDebugMode) {
          print('Error checking location service status with permission_handler: $e2');
        }
        return false;
      }
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

  AppPermissionStatus _mapGeolocatorToAppStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return AppPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return AppPermissionStatus.permanentlyDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return AppPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
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
            final permission = await Geolocator.requestPermission();
            final appStatus = PermissionManager()._mapGeolocatorToAppStatus(permission);
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