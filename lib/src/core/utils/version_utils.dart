import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for version string manipulation
/// Used for converting app version to server-compatible format
class VersionUtils {
  /// Converts version string to 3-digit format for SOAP API
  /// 
  /// Takes the FIRST DIGIT of each version component (major.minor.patch)
  /// 
  /// Examples:
  ///   "1.0.1"     → "101" (1, 0, 1)
  ///   "10.2.5"    → "125" (1, 2, 5)
  ///   "2.15.3"    → "213" (2, 1, 5)
  ///   "123.456.7" → "147" (1, 4, 7)
  ///   "1.0.0+2"   → "100" (build number ignored)
  /// 
  /// Throws [FormatException] if version format is invalid
  static String toThreeDigitFormat(String version) {
    try {
      // Remove build number (+2) if present
      final versionOnly = version.split('+').first.trim();
      
      // Validate not empty
      if (versionOnly.isEmpty) {
        throw FormatException('Version string is empty');
      }
      
      // Split by dots to get version components
      final parts = versionOnly.split('.');
      
      // Extract first digit from each component
      final digits = <String>[];
      for (int i = 0; i < 3; i++) {
        if (i < parts.length && parts[i].isNotEmpty) {
          final part = parts[i].trim();
          
          // Parse as integer to validate it's a number
          final num = int.tryParse(part);
          if (num == null) {
            throw FormatException('Invalid number in version component: $part');
          }
          
          // Take FIRST DIGIT of the number
          // For example: 10 → "1", 123 → "1", 5 → "5"
          final firstDigit = part[0];
          if (RegExp(r'^\d$').hasMatch(firstDigit)) {
            digits.add(firstDigit);
          } else {
            throw FormatException('Invalid digit in version component: $part');
          }
        } else {
          // Pad with '0' if component is missing
          digits.add('0');
        }
      }
      
      return digits.join('');
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException('Invalid version format: $version - $e');
    }
  }
  
  /// Get current app version from package info
  /// 
  /// Returns version string in format "X.Y.Z" or "X.Y.Z+build"
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// Get app version in 3-digit format for SOAP API
  /// 
  /// Convenience method that combines [getAppVersion] and [toThreeDigitFormat]
  static Future<String> getAppVersionFormatted() async {
    final version = await getAppVersion();
    return toThreeDigitFormat(version);
  }
  
  /// Validate if version string is in correct format
  /// 
  /// Returns true if version can be converted to 3-digit format
  static bool isValidVersion(String version) {
    try {
      toThreeDigitFormat(version);
      return true;
    } catch (e) {
      return false;
    }
  }
}
