/// ============================================================================
/// Client Balance Service
/// ============================================================================
/// Service for fetching, storing and managing client balance data.
/// Uses SOAP API with automatic failover between domain and IP addresses.
/// 
/// Сервис для получения, хранения и управления данными баланса клиентов.
/// Использует SOAP API с автоматическим переключением между доменом и IP адресами.
/// 
/// Mijoz balansi ma'lumotlarini olish, saqlash va boshqarish uchun service.
/// Domen va IP manzillar o'rtasida avtomatik o'tish bilan SOAP API ishlatadi.
/// 
/// Main functions / Основные функции / Asosiy funksiyalar:
/// - [fetchClientBalance] - Fetch balance from API / Получить баланс из API / API'dan balans olish
/// - [getClientBalance] - Get balance from cache / Получить баланс из кеша / Keshdan balans olish
/// - [saveClientBalance] - Save to database / Сохранить в базу данных / Bazaga saqlash
/// - [canRefresh] - Check 10-second cooldown / Проверить 10-секундный кулдаун / 10 soniyalik cooldown tekshirish
/// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

/// ============================================================================
/// ClientBalanceService - Service for working with client balances
/// Сервис для работы с балансами клиентов
/// Mijoz balanslari bilan ishlash uchun service
/// ============================================================================
class ClientBalanceService {
  /// Database service for data persistence
  /// Сервис базы данных для хранения данных
  /// Ma'lumotlarni saqlash uchun database service
  final ApiDatabaseService _dbService;
  
  /// URL failover service for automatic endpoint switching
  /// Сервис автоматического переключения между endpoint'ами
  /// Endpoint'lar o'rtasida avtomatik o'tish uchun failover service
  final UrlFailoverService _failoverService;
  
  /// Server service for accounting API configuration
  /// Сервис для конфигурации API бухгалтерии
  /// Buxgalteriya API konfiguratsiyasi uchun server service
  final ServerService _serverService;

  /// Minimum time between refreshes (in seconds)
  /// Минимальное время между обновлениями (в секундах)
  /// Yangilash orasidagi minimal vaqt (soniyalarda)
  static const int refreshCooldownSeconds = 10;

  /// Cache for fast access to balance data
  /// Кеш для быстрого доступа к данным баланса
  /// Balans ma'lumotlariga tez kirish uchun kesh
  final Map<String, ClientBalance> _cache = {};
  
  /// Last refresh times by INN
  /// Время последнего обновления по ИНН
  /// INN bo'yicha oxirgi yangilash vaqtlari
  final Map<String, DateTime> _lastRefreshTimes = {};

  ClientBalanceService({
    required ApiDatabaseService dbService,
    required UrlFailoverService failoverService,
    required ServerService serverService,
    SharedPreferencesService? prefs, // Optional, kept for backward compatibility
  })  : _dbService = dbService,
        _failoverService = failoverService,
        _serverService = serverService;

  /// ============================================================================
  /// Check if refresh is allowed (cooldown check)
  /// Проверить, разрешено ли обновление (проверка кулдауна)
  /// Yangilash mumkinligini tekshirish (cooldown tekshirish)
  /// ============================================================================
  /// Checks if 10-second cooldown has elapsed
  /// Проверяет, прошло ли 10 секунд с последнего обновления
  /// 10 soniyalik cooldown tugaganmi yoki yo'qligini tekshiradi
  /// 
  /// [inn] - Client INN number / ИНН клиента / Mijoz INN raqami
  /// Returns: true if refresh is allowed / true если обновление разрешено / true agar yangilash mumkin bo'lsa
  bool canRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return true;
    
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    return elapsed >= refreshCooldownSeconds;
  }

  /// Seconds remaining until next refresh is allowed
  /// Секунд до следующего разрешенного обновления
  /// Keyingi yangilashgacha qolgan soniyalar
  int getSecondsUntilRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return 0;
    
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    final remaining = refreshCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// ============================================================================
  /// Fetch client balance from API with automatic failover
  /// Получить баланс клиента из API с автоматическим переключением
  /// API'dan mijoz balansini avtomatik failover bilan olish
  /// ============================================================================
  /// Sends SOAP request, parses response and saves to database.
  /// Uses automatic failover between domain and IP addresses.
  /// 
  /// Отправляет SOAP запрос, парсит ответ и сохраняет в базу данных.
  /// Использует автоматическое переключение между доменом и IP адресами.
  /// 
  /// SOAP so'rov yuboradi, javobni parse qiladi va bazaga saqlaydi.
  /// Domen va IP manzillar o'rtasida avtomatik o'tishdan foydalanadi.
  /// 
  /// [inn] - Client INN number / ИНН клиента / Mijoz INN raqami
  /// [clientCode] - Client code for database linking / Код клиента для связи с БД / Mijoz kodi (clients table bilan bog'lanish uchun)
  /// [projectName] - Project name (e.g., "Evyap_-") / Название проекта (напр., "Evyap_-") / Loyiha nomi (masalan: "Evyap_-")
  /// [forceRefresh] - Ignore cooldown / Игнорировать кулдаун / Cooldown'ni e'tiborsiz qoldirish
  /// 
  /// Returns: ClientBalance or null on error / ClientBalance или null при ошибке / ClientBalance yoki null agar xatolik bo'lsa
  Future<ClientBalance?> fetchClientBalance({
    required String inn,
    String? clientCode,
    required String projectName,
    bool forceRefresh = false,
  }) async {
    // Cooldown tekshirish
    if (!forceRefresh && !canRefresh(inn)) {
      if (kDebugMode) {
        print('ClientBalanceService: Cooldown active for INN $inn, ${getSecondsUntilRefresh(inn)}s remaining');
      }
      // Keshdan qaytarish
      return _cache[inn] ?? await getClientBalanceFromDb(inn);
    }

    if (kDebugMode) {
      print('ClientBalanceService: Fetching balance for INN: $inn, Project: $projectName');
    }

    // Build SOAP request envelope
    // Создать SOAP запрос
    // SOAP so'rov yaratish
    final soapEnvelope = _buildSoapRequest(inn, projectName);

    try {
      // Execute SOAP request with automatic failover using accounting API endpoints
      // Use custom URL configuration for accounting API (shared across all projects)
      // 
      // Выполнить SOAP запрос с автоматическим переключением используя endpoint'ы API бухгалтерии
      // Использовать пользовательскую конфигурацию URL для API бухгалтерии (общий для всех проектов)
      // 
      // Buxgalteriya API endpoint'lari yordamida avtomatik failover bilan SOAP so'rov yuborish
      // Buxgalteriya API uchun maxsus URL konfiguratsiyasidan foydalanish (barcha loyihalar uchun umumiy)
      final result = await _failoverService.executeSoapWithFailover(
        body: soapEnvelope,
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
          'SOAPAction': '',
        },
        customUrlConfig: _serverService.accountingApiConfig,
      );
      
      final response = result.data;

      if (result.isSuccess && response != null) {
        // Parse XML response
        // Парсить XML ответ
        // XML javobni parse qilish
        final clientBalance = _parseSoapResponse(response, inn, clientCode, projectName);
        
        if (clientBalance != null) {
          // Save to cache for fast access
          // Сохранить в кеш для быстрого доступа
          // Tez kirish uchun keshga saqlash
          _cache[inn] = clientBalance;
          
          // Record refresh time
          // Записать время обновления
          // Yangilash vaqtini saqlash
          _lastRefreshTimes[inn] = DateTime.now();
          
          // Save to database
          // Сохранить в базу данных
          // Bazaga saqlash
          await saveClientBalance(clientBalance);
          
          if (kDebugMode) {
            print('ClientBalanceService: Successfully fetched balance for INN $inn: ${clientBalance.balance}');
            print('ClientBalanceService: Used URL: ${result.usedUrl} (fallback: ${result.usedFallback})');
          }
        }
        
        return clientBalance;
      } else {
        if (kDebugMode) {
          print('ClientBalanceService: Request failed for INN $inn: ${result.error}');
          if (result.allUrlsFailed) {
            print('ClientBalanceService: All URLs failed - returning cached data');
          }
        }
        // Return cached data on error
        // Вернуть кешированные данные при ошибке
        // Xatolikda kesh ma'lumotlarini qaytarish
        return _cache[inn] ?? await getClientBalanceFromDb(inn);
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Unexpected error fetching balance for INN $inn: $e');
      }
      // Return cached data on unexpected error
      // Вернуть кешированные данные при неожиданной ошибке
      // Kutilmagan xatolikda kesh ma'lumotlarini qaytarish
      return _cache[inn] ?? await getClientBalanceFromDb(inn);
    }
  }

  /// ============================================================================
  /// Build SOAP request envelope
  /// Создать SOAP запрос
  /// SOAP so'rov yaratish
  /// ============================================================================
  String _buildSoapRequest(String inn, String projectName) {
    return '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GeClientBalance>
         <sam:INN>$inn</sam:INN>
         <sam:Project>$projectName</sam:Project>
      </sam:GeClientBalance>
   </soap:Body>
</soap:Envelope>''';
  }

  /// ============================================================================
  /// Parse SOAP response XML
  /// Парсить SOAP ответ XML
  /// SOAP javobini parse qilish
  /// ============================================================================
  ClientBalance? _parseSoapResponse(String xmlString, String inn, String? clientCode, String projectName) {
    try {
      final document = XmlDocument.parse(xmlString);
      
      // <m:return> elementini topish
      final returnElement = document.findAllElements('m:return').firstOrNull;
      if (returnElement == null) {
        if (kDebugMode) {
          print('ClientBalanceService: No return element found in response');
        }
        return null;
      }

      // Umumiy balansni olish
      final balanceStr = returnElement.findAllElements('m:balance').firstOrNull?.innerText ?? '0';
      final balance = double.tryParse(balanceStr) ?? 0.0;

      // Shartnomalar bo'yicha balans
      final contractBalances = <ClientBalanceByContract>[];
      final contractElements = returnElement.findAllElements('m:ClientBalanceByContract');
      for (final element in contractElements) {
        final contract = _parseContractBalance(element);
        if (contract != null) {
          contractBalances.add(contract);
        }
      }

      // Buyurtmalar bo'yicha balans
      final orderBalances = <ClientBalanceByOrder>[];
      final orderElements = returnElement.findAllElements('m:ClientBalanceByOrder');
      for (final element in orderElements) {
        final order = _parseOrderBalance(element);
        if (order != null) {
          orderBalances.add(order);
        }
      }

      if (kDebugMode) {
        print('ClientBalanceService: Parsed balance=$balance, contracts=${contractBalances.length}, orders=${orderBalances.length}');
      }

      return ClientBalance(
        inn: inn,
        clientCode: clientCode,
        balance: balance,
        contractBalances: contractBalances,
        orderBalances: orderBalances,
        lastUpdated: DateTime.now(),
        projectName: projectName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error parsing SOAP response: $e');
      }
      return null;
    }
  }

  /// Parse contract balance from XML element
  /// Парсить баланс по договору из XML элемента
  /// Shartnoma balansini XML elementdan parse qilish
  ClientBalanceByContract? _parseContractBalance(XmlElement element) {
    try {
      final xmlData = <String, String>{};
      
      // Barcha child elementlarni o'qish
      for (final child in element.children.whereType<XmlElement>()) {
        final localName = child.name.local;
        xmlData[localName] = child.innerText;
      }

      return ClientBalanceByContract.fromXml(xmlData);
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error parsing contract balance: $e');
      }
      return null;
    }
  }

  /// Parse order balance from XML element
  /// Парсить баланс по заказу из XML элемента
  /// Buyurtma balansini XML elementdan parse qilish
  ClientBalanceByOrder? _parseOrderBalance(XmlElement element) {
    try {
      final xmlData = <String, String>{};
      
      // Barcha child elementlarni o'qish
      for (final child in element.children.whereType<XmlElement>()) {
        final localName = child.name.local;
        xmlData[localName] = child.innerText;
      }

      return ClientBalanceByOrder.fromXml(xmlData);
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error parsing order balance: $e');
      }
      return null;
    }
  }

  /// ============================================================================
  /// Get balance from cache
  /// Получить баланс из кеша
  /// Keshdan balans olish
  /// ============================================================================
  ClientBalance? getClientBalanceFromCache(String inn) {
    return _cache[inn];
  }

  /// ============================================================================
  /// Get balance from database
  /// Получить баланс из базы данных
  /// Bazadan balans olish
  /// ============================================================================
  Future<ClientBalance?> getClientBalanceFromDb(String inn) async {
    try {
      final db = await _dbService.database;
      
      // Asosiy balans ma'lumotlarini olish
      final balanceResult = await db.query(
        'client_balances',
        where: 'inn = ?',
        whereArgs: [inn],
        limit: 1,
      );

      if (balanceResult.isEmpty) {
        return null;
      }

      final balanceRow = balanceResult.first;
      
      // Shartnomalar ro'yxatini olish
      final contractsResult = await db.query(
        'client_balance_contracts',
        where: 'inn = ?',
        whereArgs: [inn],
      );

      final contractBalances = contractsResult
          .map((row) => ClientBalanceByContract.fromJson(row))
          .toList();

      // Buyurtmalar ro'yxatini olish
      final ordersResult = await db.query(
        'client_balance_orders',
        where: 'inn = ?',
        whereArgs: [inn],
      );

      final orderBalances = ordersResult
          .map((row) => ClientBalanceByOrder.fromJson(row))
          .toList();

      final clientBalance = ClientBalance(
        inn: inn,
        clientCode: balanceRow['client_code'] as String?,
        balance: (balanceRow['balance'] as num?)?.toDouble() ?? 0.0,
        contractBalances: contractBalances,
        orderBalances: orderBalances,
        lastUpdated: DateTime.parse(balanceRow['last_updated'] as String),
        projectName: balanceRow['project_name'] as String? ?? '',
      );

      // Keshga saqlash
      _cache[inn] = clientBalance;

      return clientBalance;
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error getting balance from DB for INN $inn: $e');
      }
      return null;
    }
  }

  /// ============================================================================
  /// Save balance to database
  /// Сохранить баланс в базу данных
  /// Balansni bazaga saqlash
  /// ============================================================================
  Future<void> saveClientBalance(ClientBalance balance) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      // Transaction ichida saqlash
      await db.transaction((txn) async {
        // Eski ma'lumotlarni o'chirish
        await txn.delete('client_balances', where: 'inn = ?', whereArgs: [balance.inn]);
        await txn.delete('client_balance_contracts', where: 'inn = ?', whereArgs: [balance.inn]);
        await txn.delete('client_balance_orders', where: 'inn = ?', whereArgs: [balance.inn]);

        // Asosiy balansni saqlash
        await txn.insert('client_balances', {
          'inn': balance.inn,
          'client_code': balance.clientCode,
          'balance': balance.balance,
          'project_name': balance.projectName,
          'last_updated': balance.lastUpdated.toIso8601String(),
          'created_at': now,
          'updated_at': now,
        });

        // Shartnomalarni saqlash
        for (final contract in balance.contractBalances) {
          await txn.insert('client_balance_contracts', {
            'inn': balance.inn,
            'client_code': balance.clientCode,
            ...contract.toJson(),
            'created_at': now,
            'updated_at': now,
          });
        }

        // Buyurtmalarni saqlash
        for (final order in balance.orderBalances) {
          await txn.insert('client_balance_orders', {
            'inn': balance.inn,
            'client_code': balance.clientCode,
            ...order.toJson(),
            'created_at': now,
            'updated_at': now,
          });
        }
      });

      if (kDebugMode) {
        print('ClientBalanceService: Saved balance for INN ${balance.inn} to database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error saving balance to DB: $e');
      }
    }
  }

  /// ============================================================================
  /// Delete balance from database and cache
  /// Удалить баланс из базы данных и кеша
  /// Balansni bazadan va keshdan o'chirish
  /// ============================================================================
  Future<void> deleteClientBalance(String inn) async {
    try {
      final db = await _dbService.database;
      
      await db.delete('client_balances', where: 'inn = ?', whereArgs: [inn]);
      await db.delete('client_balance_contracts', where: 'inn = ?', whereArgs: [inn]);
      await db.delete('client_balance_orders', where: 'inn = ?', whereArgs: [inn]);
      
      _cache.remove(inn);
      _lastRefreshTimes.remove(inn);

      if (kDebugMode) {
        print('ClientBalanceService: Deleted balance for INN $inn');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error deleting balance: $e');
      }
    }
  }

  /// ============================================================================
  /// Clear all balances from database and cache
  /// Очистить все балансы из базы данных и кеша
  /// Barcha balanslarni bazadan va keshdan o'chirish
  /// ============================================================================
  Future<void> clearAllBalances() async {
    try {
      final db = await _dbService.database;
      
      await db.delete('client_balances');
      await db.delete('client_balance_contracts');
      await db.delete('client_balance_orders');
      
      _cache.clear();
      _lastRefreshTimes.clear();

      if (kDebugMode) {
        print('ClientBalanceService: Cleared all balances');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error clearing all balances: $e');
      }
    }
  }

  /// ============================================================================
  /// Get count of all saved balances
  /// Получить количество всех сохраненных балансов
  /// Barcha saqlangan balanslar sonini olish
  /// ============================================================================
  Future<int> getBalanceCount() async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM client_balances');
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// ============================================================================
  /// Get project name for server
  /// Получить название проекта для сервера
  /// Server uchun loyiha nomini olish
  /// ============================================================================
  /// Returns project name for API request based on server name
  /// Возвращает название проекта для API запроса на основе имени сервера
  /// Server nomi asosida API so'rovi uchun loyiha nomini qaytaradi
  String getProjectNameForServer(String? serverName) {
    // Server nomiga qarab loyiha nomini qaytarish
    switch (serverName?.toLowerCase()) {
      case 'evyap':
        return 'Evyap_-';
      case 'garnier':
        return 'Garnier_-';
      case 'ppd':
        return 'PPD_-';
      case 'avon':
        return 'Avon_-';
      case 'avontest':
        return 'AvonTest_-';
      default:
        return 'Evyap_-'; // Default
    }
  }

  /// ============================================================================
  /// Get failover statistics
  /// Получить статистику переключений
  /// Failover statistikasini olish
  /// ============================================================================
  /// Returns status and statistics of all URLs
  /// Возвращает статус и статистику всех URL
  /// Barcha URL'larning holati va statistikasini qaytaradi
  Map<String, UrlStatus> getFailoverStatistics() {
    return _failoverService.urlStatuses;
  }

  /// ============================================================================
  /// Reset URL statuses and return to primary
  /// Сбросить статусы URL и вернуться к основному
  /// URL statuslarini qayta tiklash va asosiyga qaytish
  /// ============================================================================
  /// Resets all URL statuses and forces retry from primary URL
  /// Сбрасывает все статусы URL и принудительно пытается использовать основной URL
  /// Barcha URL statuslarini qayta tiklaydi va asosiy URL'dan qayta urinadi
  Future<void> resetEndpointStatus() async {
    await _failoverService.reset();
    if (kDebugMode) {
      print('ClientBalanceService: URL statuses reset to primary');
    }
  }

  /// ============================================================================
  /// Get accounting API URL configuration
  /// Получить конфигурацию URL API бухгалтерии
  /// Buxgalteriya API URL konfiguratsiyasini olish
  /// ============================================================================
  /// Returns URL configuration with primary and fallback URLs
  /// Возвращает конфигурацию URL с основным и резервными адресами
  /// Asosiy va zaxira URL'lar bilan konfiguratsiyani qaytaradi
  ServerUrlConfig getAccountingApiConfig() {
    return _serverService.accountingApiConfig;
  }
}
