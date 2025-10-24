# Map Tokens Implementation Documentation

## Overview

Bu hujjatda Gloria Marketing Flutter ilovasida Yandex va Google xarita tokenlarini serverdan olish va shared preferencesga saqlash funksiyasining amalga oshirilishi batafsil tavsiflanadi.

## Arxitektura

### Komponentlar

1. **SoapApiService** - Server bilan SOAP API orqali aloqa
2. **SharedPreferencesService** - Tokenlarni lokal saqlash
3. **DataSyncService** - Sinxronlash jarayonini boshqarish
4. **DataSyncProgressWidget** - Foydalanuvchiga progress ko'rsatish

### API Spetsifikatsiyasi

#### getMapTokens SOAP So'rovi
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getMapTokens>
         <sam:CodeUser>000000109</sam:CodeUser>
      </sam:getMapTokens>
   </soap:Body>
</soap:Envelope>
```

#### getMapTokens SOAP Javobi
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:getMapTokensResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:yandexToken>6381d1cf-a0d8-4b88-8c8f-60951f817884</m:yandexToken>
        <m:googleToken>AIzaSyDummyGoogleToken123456789</m:googleToken>
      </m:return>
    </m:getMapTokensResponse>
  </soap:Body>
</soap:Envelope>
```

## Amalga oshirilgan funksiyalar

### 1. SoapApiService.getMapTokens()

**Joylashgan fayl:** `lib/src/core/services/soap_api_service.dart`

**Tavsif:** Serverdan Yandex va Google xarita tokenlarini oladi.

**Parametrlar:**
- `userCode` (required): Foydalanuvchi kodi

**Qaytaradi:** `Map<String, String>` - yandexToken va googleToken kalitlari bilan

**Xatoliklar:**
- Agar server javob bermasa yoki XML parsing xatosi yuz bersa, Exception tashlaydi

### 2. SharedPreferencesService Map Token Metodlari

**Joylashgan fayl:** `lib/src/core/services/shared_preferences_service.dart`

#### saveMapTokens()
- Tokenlarni shared preferencesga saqlaydi
- Oxirgi yangilanish vaqtini saqlaydi

#### getMapTokens()
- Saqlangan tokenlarni qaytaradi

#### hasValidMapTokens()
- Tokenlar mavjud va 30 kundan kam vaqt o'tganligini tekshiradi

#### getMapTokensLastUpdated()
- Oxirgi yangilanish vaqtini qaytaradi

### 3. DataSyncService.syncMapTokens()

**Joylashgan fayl:** `lib/src/core/services/data_sync_service.dart`

**Tavsif:** To'liq sinxronlash jarayonida map tokenlarini oladi va saqlaydi.

**Xususiyatlar:**
- SOAP API orqali serverdan tokenlarni oladi
- Shared preferencesga saqlaydi
- Xatolik yuz berganda log yozadi lekin sinxronlashni to'xtatmaydi

### 4. Sinxronlash jarayoniga integratsiya

Map tokenlari quyidagi sinxronlash jarayonlariga kiritilgan:

#### syncAllUserData() - oddiy sinxronlash
- Barcha ma'lumotlardan keyin map tokenlari olinadi

#### syncAllUserDataWithProgress() - progress bilan sinxronlash
- "Xarita tokenlari yuklanmoqda..." bosqichi qo'shilgan

## Xatolik boshqaruvi

### Tarmoq xatoliklari
- DioException - tarmoq uzilishi, timeout
- Agar API mavjud bo'lmasa, xatolik logga yoziladi lekin sinxronlash davom etadi

### Ma'lumot parsing xatoliklari
- XML parsing xatosi
- Null qiymatlar bilan ishlash

### Saqlash xatoliklari
- Shared preferences yozish xatosi
- Agar saqlash muvaffaqiyatsiz bo'lsa, Exception tashlanadi

## Testlar

### Unit testlar
- **soap_api_service_map_tokens_test.dart** - SOAP API testlari
- **map_tokens_integration_test.dart** - Integratsion testlar

### Test qamrovi
- Muvaffaqiyatli token olish
- Bo'sh tokenlar
- Qisman tokenlar (faqat Yandex yoki faqat Google)
- Tarmoq xatoliklari
- XML parsing xatoliklari
- Server xatoliklari

## Xavfsizlik

### Tokenlar saqlanishi
- Shared preferencesda lokal saqlanadi
- Encryption qo'shilmagan (kerak bo'lsa, keychain ishlatish mumkin)

### Validatsiya
- Tokenlar 30 kundan ortiq bo'lsa, eskirgan deb hisoblanadi
- Har sinxronlashda yangilanadi

## Monitoring va loglash

### Debug rejimi
- Barcha muhim operatsiyalar logga yoziladi
- Token qiymatlari faqat mavjudligi ko'rsatiladi (xavfsizlik uchun)

### Xatolik loglari
- API chaqiruv xatoliklari
- Parsing xatoliklari
- Saqlash xatoliklari

## Foydalanish

### Manual sinxronlash
```dart
final dataSyncService = DataSyncService(...);
final tokens = await dataSyncService.syncMapTokens(userCode: '000000109');
```

### Tokenlarni tekshirish
```dart
final prefsService = SharedPreferencesService.getInstance();
final hasValidTokens = prefsService.hasValidMapTokens();
final tokens = prefsService.getMapTokens();
```

### Xarita xizmatlarida ishlatish
```dart
final yandexToken = prefsService.getYandexMapsToken();
final googleToken = prefsService.getGoogleMapsToken();

// Xarita xizmatlariga uzatish
```

## Kelajakdagi yaxshilashlar

1. **Encryption** - Tokenlarni shifrlash
2. **Token refresh** - Avtomatik yangilanish mexanizmi
3. **Fallback tokens** - Server ishlamayotganda zaxira tokenlar
4. **Token validation** - Serverda tokenlarni tekshirish
5. **Multi-user support** - Bir nechta foydalanuvchi uchun tokenlar

## Xulosa

Map tokens funksiyasi muvaffaqiyatli amalga oshirildi va mavjud sinxronlash tizimiga uzluksiz integratsiya qilindi. Barcha xatolik holatlari ko'zda tutilgan va testlar yozilgan. Tizim production-ready holatda.