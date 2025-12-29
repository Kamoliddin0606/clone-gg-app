import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// =============================================================================
/// Local UUID Service
/// =============================================================================
/// 
/// Bu servis qurilmani aniqlash uchun local UUID yaratadi va saqlaydi.
/// UUID flutter_secure_storage orqali xavfsiz saqlanadi.
/// 
/// MAQSAD:
/// - Qurilmani serverga yuborish uchun unikal identifikator
/// - Backend fingerprint matching uchun signal
/// - IMEI, MAC, serial number ishlatilMAYDI (privacy)
/// =============================================================================

class LocalUuidService {
  static const String _key = 'local_device_uuid';
  
  final FlutterSecureStorage _storage;
  
  /// Cached UUID qiymati (har safar storage'ga murojaat qilmaslik uchun)
  String? _cachedUuid;
  
  LocalUuidService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Local UUID ni olish yoki yangi yaratish
  /// 
  /// Agar UUID mavjud bo'lsa, qaytaradi.
  /// Agar mavjud bo'lmasa, yangi UUID yaratadi va saqlaydi.
  Future<String> getOrCreateLocalUuid() async {
    // Cached qiymat mavjud bo'lsa, qaytarish
    if (_cachedUuid != null && _cachedUuid!.isNotEmpty) {
      return _cachedUuid!;
    }
    
    try {
      // Storage'dan o'qish
      String? uuid = await _storage.read(key: _key);
      
      // Agar mavjud bo'lmasa yoki bo'sh bo'lsa, yangi yaratish
      if (uuid == null || uuid.isEmpty) {
        uuid = const Uuid().v4();
        await _storage.write(key: _key, value: uuid);
      }
      
      // Cache'ga saqlash
      _cachedUuid = uuid;
      return uuid;
    } catch (e) {
      // Xatolik bo'lsa, vaqtinchalik UUID yaratish
      // (bu holatda har safar yangi UUID bo'ladi)
      final tempUuid = const Uuid().v4();
      _cachedUuid = tempUuid;
      return tempUuid;
    }
  }

  /// Local UUID mavjudligini tekshirish
  Future<bool> hasLocalUuid() async {
    try {
      final uuid = await _storage.read(key: _key);
      return uuid != null && uuid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Local UUID ni o'chirish (faqat logout yoki reset holatlarida)
  /// 
  /// DIQQAT: Bu metod faqat maxsus holatlarda ishlatilishi kerak!
  /// UUID o'chirilsa, server yangi qurilma deb tushunishi mumkin.
  Future<void> clearLocalUuid() async {
    try {
      await _storage.delete(key: _key);
      _cachedUuid = null;
    } catch (e) {
      // Xatolikni log qilish, lekin throw qilmaslik
      _cachedUuid = null;
    }
  }

  /// Cache'ni tozalash (storage'ni o'zgartirmaydi)
  void clearCache() {
    _cachedUuid = null;
  }
}
