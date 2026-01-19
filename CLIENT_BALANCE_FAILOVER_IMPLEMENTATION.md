# Client Balance Service - Failover Implementation

## Overview / Обзор / Umumiy ma'lumot

The `ClientBalanceService` uses automatic URL failover mechanism to ensure reliable access to accounting API across multiple endpoints (domain and IP addresses).

Сервис `ClientBalanceService` использует механизм автоматического переключения URL для обеспечения надежного доступа к API бухгалтерии через несколько конечных точек (домен и IP адреса).

`ClientBalanceService` buxgalteriya API'ga ishonchli kirishni ta'minlash uchun bir nechta endpoint'lar (domen va IP manzillar) orqali avtomatik URL failover mexanizmidan foydalanadi.

---

## Architecture / Архитектура / Arxitektura

### Components / Компоненты / Komponentlar

1. **ServerService** - Manages server configurations and URL endpoints
   - Управляет конфигурациями серверов и URL конечными точками
   - Server konfiguratsiyalari va URL endpoint'larini boshqaradi

2. **UrlFailoverService** - Handles automatic failover between URLs
   - Обрабатывает автоматическое переключение между URL
   - URL'lar o'rtasida avtomatik o'tishni boshqaradi

3. **ClientBalanceService** - Fetches and manages client balance data
   - Получает и управляет данными баланса клиентов
   - Mijoz balansi ma'lumotlarini oladi va boshqaradi

---

## URL Configuration / Конфигурация URL / URL Konfiguratsiyasi

### Accounting API Endpoints / Конечные точки API бухгалтерии / Buxgalteriya API Endpoint'lari

The accounting API is shared across all projects and uses the following endpoints in priority order:

API бухгалтерии общий для всех проектов и использует следующие конечные точки в порядке приоритета:

Buxgalteriya API barcha loyihalar uchun umumiy va quyidagi endpoint'larni prioritet tartibida ishlatadi:

1. **Primary (Domain)**: `http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Highest priority / Наивысший приоритет / Eng yuqori prioritet
   - Used first / Используется первым / Birinchi ishlatiladi

2. **Fallback IP 1**: `http://178.218.200.120:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Used if primary fails / Используется если основной не работает / Asosiy ishlamasa ishlatiladi

3. **Fallback IP 2**: `http://109.94.175.104:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Used if both primary and IP 1 fail / Используется если оба предыдущих не работают / Ikkalasi ham ishlamasa ishlatiladi

---

## How It Works / Как это работает / Qanday ishlaydi

### Key Implementation Detail / Ключевая деталь реализации / Asosiy implementatsiya tafsiloti

**ClientBalanceService** uses a **custom URL configuration** that is independent of the project-specific endpoints. This is achieved by passing `accountingApiConfig` to the `UrlFailoverService`:

**ClientBalanceService** использует **пользовательскую конфигурацию URL**, которая не зависит от endpoint'ов конкретного проекта. Это достигается передачей `accountingApiConfig` в `UrlFailoverService`:

**ClientBalanceService** loyiha-spetsifik endpoint'lardan mustaqil bo'lgan **maxsus URL konfiguratsiyasidan** foydalanadi. Bu `accountingApiConfig`ni `UrlFailoverService`ga uzatish orqali amalga oshiriladi:

```dart
final result = await _failoverService.executeSoapWithFailover(
  body: soapEnvelope,
  headers: {...},
  customUrlConfig: _serverService.accountingApiConfig, // ← Custom config
);
```

This ensures that:
- Accounting API uses its own endpoints (`/gloriya_buh2/gloriya_buh2.1cws`)
- Project-specific APIs use their own endpoints (`/EVYAP_UT/EVYAP_UT.1cws`, etc.)
- Both use the same failover mechanism with the same hosts and ports
- No interference between different API types

Это гарантирует:
- API бухгалтерии использует свои endpoint'ы (`/gloriya_buh2/gloriya_buh2.1cws`)
- API конкретных проектов используют свои endpoint'ы (`/EVYAP_UT/EVYAP_UT.1cws`, и т.д.)
- Оба используют один механизм failover с одинаковыми хостами и портами
- Нет вмешательства между разными типами API

Bu quyidagilarni ta'minlaydi:
- Buxgalteriya API o'z endpoint'laridan foydalanadi (`/gloriya_buh2/gloriya_buh2.1cws`)
- Loyiha-spetsifik API'lar o'z endpoint'laridan foydalanadi (`/EVYAP_UT/EVYAP_UT.1cws`, va h.k.)
- Ikkalasi ham bir xil failover mexanizmidan bir xil host va portlar bilan foydalanadi
- Turli API turlari o'rtasida aralashish yo'q

### Automatic Failover Process / Процесс автоматического переключения / Avtomatik o'tish jarayoni

1. **Request Initiation** / Инициация запроса / So'rov boshlash
   - Service attempts to fetch balance data using accounting API config
   - Сервис пытается получить данные баланса используя конфигурацию API бухгалтерии
   - Servis buxgalteriya API konfiguratsiyasidan foydalanib balans ma'lumotlarini olishga harakat qiladi

2. **Primary URL Try** / Попытка основного URL / Asosiy URL'ni sinash
   - First tries: `http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Сначала пробует: `http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Avval sinaydi: `http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws`

3. **Automatic Fallback** / Автоматический откат / Avtomatik zaxiraga o'tish
   - If primary fails, tries: `http://178.218.200.120:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Если основной не работает, пробует: `http://178.218.200.120:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Agar asosiy ishlamasa, sinaydi: `http://178.218.200.120:5443/gloriya_buh2/gloriya_buh2.1cws`
   - If IP 1 fails, tries: `http://109.94.175.104:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Если IP 1 не работает, пробует: `http://109.94.175.104:5443/gloriya_buh2/gloriya_buh2.1cws`
   - Agar IP 1 ishlamasa, sinaydi: `http://109.94.175.104:5443/gloriya_buh2/gloriya_buh2.1cws`

4. **Success Handling** / Обработка успеха / Muvaffaqiyatni qayta ishlash
   - Records successful URL (does not affect project-specific URL tracking)
   - Записывает успешный URL (не влияет на отслеживание URL конкретного проекта)
   - Muvaffaqiyatli URL'ni yozadi (loyiha-spetsifik URL kuzatuviga ta'sir qilmaydi)
   - Caches balance data for fast access
   - Кеширует данные баланса для быстрого доступа
   - Tez kirish uchun balans ma'lumotlarini keshlaydi

5. **Periodic Primary Retry** / Периодическая попытка основного / Davriy asosiy URL'ni sinash
   - Every 5 minutes, tries primary URL again
   - Каждые 5 минут пробует основной URL снова
   - Har 5 daqiqada asosiy URL'ni qayta sinaydi
   - Automatically switches back if primary is available
   - Автоматически переключается обратно если основной доступен
   - Asosiy mavjud bo'lsa avtomatik qaytadi

---

## Usage Examples / Примеры использования / Foydalanish misollari

### Fetching Client Balance / Получение баланса клиента / Mijoz balansini olish

```dart
// Get service instance
final clientBalanceService = sl<ClientBalanceService>();

// Fetch balance with automatic failover
final balance = await clientBalanceService.fetchClientBalance(
  inn: '123456789',
  clientCode: 'CLIENT001',
  projectName: 'Evyap_-',
);

if (balance != null) {
  print('Balance: ${balance.balance}');
  print('Contracts: ${balance.contractBalances.length}');
  print('Orders: ${balance.orderBalances.length}');
}
```

### Getting Failover Statistics / Получение статистики переключений / Failover statistikasini olish

```dart
// Get URL status information
final stats = clientBalanceService.getFailoverStatistics();

for (var entry in stats.entries) {
  final url = entry.key;
  final status = entry.value;
  
  print('URL: $url');
  print('Available: ${status.isAvailable}');
  print('Failures: ${status.failureCount}');
  print('Last Success: ${status.lastSuccess}');
}
```

### Resetting to Primary URL / Сброс к основному URL / Asosiy URL'ga qaytish

```dart
// Force reset to primary URL
await clientBalanceService.resetEndpointStatus();

// Next request will try primary URL first
final balance = await clientBalanceService.fetchClientBalance(
  inn: '123456789',
  clientCode: 'CLIENT001',
  projectName: 'Evyap_-',
  forceRefresh: true,
);
```

---

## Configuration / Конфигурация / Konfiguratsiya

### Adding New Endpoints / Добавление новых конечных точек / Yangi endpoint'lar qo'shish

To add new fallback endpoints, update `_ServerHosts` in `server_service.dart`:

Чтобы добавить новые резервные конечные точки, обновите `_ServerHosts` в `server_service.dart`:

Yangi zaxira endpoint'lar qo'shish uchun `server_service.dart` faylidagi `_ServerHosts`ni yangilang:

```dart
class _ServerHosts {
  static const String domainHost = 'kit.gloriya.uz';
  static const String ipHost1 = '178.218.200.120';
  static const String ipHost2 = '109.94.175.104';
  static const String ipHost3 = 'NEW_IP_ADDRESS'; // Add new IP
  static const int port = 5443;

  static ServerUrlConfig get accountingApiConfig => ServerUrlConfig(
    primaryUrl: buildUrl(domainHost, accountingApiPath),
    fallbackUrls: [
      buildUrl(ipHost1, accountingApiPath),
      buildUrl(ipHost2, accountingApiPath),
      buildUrl(ipHost3, accountingApiPath), // Add to fallback list
    ],
    servicePath: accountingApiPath,
  );
}
```

### Adjusting Failover Settings / Настройка параметров переключения / Failover sozlamalarini o'zgartirish

Modify `FailoverConfig` in `url_failover_service.dart`:

Измените `FailoverConfig` в `url_failover_service.dart`:

`url_failover_service.dart` faylidagi `FailoverConfig`ni o'zgartiring:

```dart
class FailoverConfig {
  final int connectionTimeoutMs;        // Default: 8000 (8 seconds)
  final int receiveTimeoutMs;           // Default: 15000 (15 seconds)
  final int primaryUrlRetryIntervalMinutes; // Default: 5 minutes
  final int maxFailuresPerUrl;          // Default: 1
}
```

---

## Features / Особенности / Xususiyatlar

### 1. Automatic Failover / Автоматическое переключение / Avtomatik o'tish
- ✅ Seamless switching between endpoints
- ✅ Плавное переключение между конечными точками
- ✅ Endpoint'lar o'rtasida muammosiz o'tish

### 2. Smart Caching / Умное кеширование / Aqlli keshlash
- ✅ In-memory cache for fast access
- ✅ Кеш в памяти для быстрого доступа
- ✅ Tez kirish uchun xotiradagi kesh
- ✅ Database persistence
- ✅ Сохранение в базе данных
- ✅ Bazada saqlash

### 3. Cooldown Protection / Защита от частых запросов / Tez-tez so'rovlardan himoya
- ✅ 10-second cooldown between refreshes
- ✅ 10-секундная задержка между обновлениями
- ✅ Yangilashlar orasida 10 soniyalik kechikish

### 4. Health Monitoring / Мониторинг здоровья / Sog'likni kuzatish
- ✅ Tracks URL availability
- ✅ Отслеживает доступность URL
- ✅ URL mavjudligini kuzatadi
- ✅ Records success/failure times
- ✅ Записывает время успехов/неудач
- ✅ Muvaffaqiyat/xatolik vaqtlarini yozadi

### 5. Automatic Recovery / Автоматическое восстановление / Avtomatik tiklanish
- ✅ Periodic retry of primary URL
- ✅ Периодическая попытка основного URL
- ✅ Asosiy URL'ni davriy sinash
- ✅ Automatic switch back when available
- ✅ Автоматический возврат когда доступен
- ✅ Mavjud bo'lganda avtomatik qaytish

---

## Error Handling / Обработка ошибок / Xatolarni qayta ishlash

### Connection Errors / Ошибки подключения / Ulanish xatoliklari

When all endpoints fail:
- Returns cached data if available
- Returns database data as fallback
- Returns null if no cached/database data

Когда все конечные точки не работают:
- Возвращает кешированные данные если доступны
- Возвращает данные из базы как резерв
- Возвращает null если нет кеша/данных в БД

Barcha endpoint'lar ishlamasa:
- Mavjud bo'lsa kesh ma'lumotlarini qaytaradi
- Zaxira sifatida baza ma'lumotlarini qaytaradi
- Kesh/baza ma'lumotlari bo'lmasa null qaytaradi

### Debug Logging / Отладочное логирование / Debug loglar

In debug mode, detailed logs are printed:

В режиме отладки выводятся подробные логи:

Debug rejimida batafsil loglar chiqariladi:

```
ClientBalanceService: Fetching balance for INN: 123456789, Project: Evyap_-
[UrlFailover] Trying URL [0]: http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws
[UrlFailover] Success with URL: http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws (fallback: false)
ClientBalanceService: Successfully fetched balance for INN 123456789: 1000000.0
ClientBalanceService: Used URL: http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws (fallback: false)
```

---

## Integration with Existing Code / Интеграция с существующим кодом / Mavjud kod bilan integratsiya

### No Breaking Changes / Без критических изменений / Buzilishlar yo'q

The refactoring maintains backward compatibility:
- All existing method signatures unchanged
- Same return types and parameters
- Existing code continues to work without modifications

Рефакторинг сохраняет обратную совместимость:
- Все существующие сигнатуры методов не изменены
- Те же типы возврата и параметры
- Существующий код продолжает работать без изменений

Refaktoring orqaga moslikni saqlaydi:
- Barcha mavjud metod signaturalari o'zgartirilmagan
- Bir xil qaytish turlari va parametrlar
- Mavjud kod o'zgartirishsiz ishlashda davom etadi

### Service Locator Registration / Регистрация в Service Locator / Service Locator'da ro'yxatdan o'tkazish

The service is automatically registered in `service_locator.dart`:

Сервис автоматически регистрируется в `service_locator.dart`:

Servis avtomatik ravishda `service_locator.dart`da ro'yxatdan o'tkaziladi:

```dart
if (!sl.isRegistered<ClientBalanceService>()) {
  sl.registerLazySingleton<ClientBalanceService>(() => ClientBalanceService(
    dbService: sl<ApiDatabaseService>(),
    failoverService: sl<UrlFailoverService>(),
    serverService: sl<ServerService>(),
    prefs: sl<SharedPreferencesService>(),
  ));
}
```

---

## Benefits / Преимущества / Afzalliklar

### Reliability / Надежность / Ishonchlilik
- ✅ Continues working even if primary server is down
- ✅ Продолжает работать даже если основной сервер не работает
- ✅ Asosiy server ishlamasa ham ishlashda davom etadi

### Performance / Производительность / Ishlash tezligi
- ✅ Fast failover (8-second timeout per URL)
- ✅ Быстрое переключение (8-секундный таймаут на URL)
- ✅ Tez o'tish (har bir URL uchun 8 soniyalik timeout)
- ✅ Cached data for instant access
- ✅ Кешированные данные для мгновенного доступа
- ✅ Bir zumda kirish uchun keshlangan ma'lumotlar

### Maintainability / Поддерживаемость / Ta'minlanish
- ✅ Centralized configuration in ServerService
- ✅ Централизованная конфигурация в ServerService
- ✅ ServerService'da markazlashtirilgan konfiguratsiya
- ✅ Easy to add new endpoints
- ✅ Легко добавлять новые конечные точки
- ✅ Yangi endpoint'lar qo'shish oson

### Monitoring / Мониторинг / Kuzatish
- ✅ Detailed statistics available
- ✅ Доступна подробная статистика
- ✅ Batafsil statistika mavjud
- ✅ Debug logs for troubleshooting
- ✅ Отладочные логи для устранения неполадок
- ✅ Muammolarni hal qilish uchun debug loglar

---

## Testing / Тестирование / Sinov

### Manual Testing / Ручное тестирование / Qo'lda sinov

1. Test with primary URL working:
   - Should use domain URL
   - Should be fast (no failover delay)

2. Test with primary URL down:
   - Should automatically switch to IP 1
   - Should continue working seamlessly

3. Test with all URLs down:
   - Should return cached data
   - Should return database data if no cache
   - Should return null if no data available

### Automated Testing / Автоматизированное тестирование / Avtomatlashtirilgan sinov

Unit tests should cover:
- Failover logic
- Caching behavior
- Cooldown mechanism
- Error handling

---

## Summary / Резюме / Xulosa

The `ClientBalanceService` now uses the existing `UrlFailoverService` architecture for reliable, automatic failover between multiple endpoints. This ensures the app continues to function even when the primary server is unavailable, providing a better user experience.

`ClientBalanceService` теперь использует существующую архитектуру `UrlFailoverService` для надежного автоматического переключения между несколькими конечными точками. Это гарантирует, что приложение продолжит работать даже когда основной сервер недоступен, обеспечивая лучший пользовательский опыт.

`ClientBalanceService` endi bir nechta endpoint'lar o'rtasida ishonchli, avtomatik o'tish uchun mavjud `UrlFailoverService` arxitekturasidan foydalanadi. Bu asosiy server mavjud bo'lmasa ham ilova ishlashda davom etishini ta'minlaydi va foydalanuvchi tajribasini yaxshilaydi.

---

**Last Updated / Последнее обновление / Oxirgi yangilanish**: January 19, 2026
