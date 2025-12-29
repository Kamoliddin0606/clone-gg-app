/// ============================================================================
/// Client Balance Service
/// ============================================================================
/// Bu service mijoz balansi ma'lumotlarini olish, saqlash va boshqarish uchun
/// javobgar. SOAP API orqali http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws?wsdl
/// manzilidan ma'lumotlarni oladi.
/// 
/// Asosiy funksiyalar:
/// - [fetchClientBalance] - API'dan balans olish
/// - [getClientBalance] - Keshdan balans olish
/// - [saveClientBalance] - Bazaga saqlash
/// - [canRefresh] - 10 soniyalik cooldown tekshirish
/// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// ============================================================================
/// ClientBalanceService - Mijoz balansi bilan ishlash uchun service
/// ============================================================================
class ClientBalanceService {
  /// Dio HTTP client instance
  final Dio _dio;
  
  /// Database service - ma'lumotlarni saqlash uchun
  final ApiDatabaseService _dbService;
  
  /// Buxgalteriya SOAP API endpoint - barcha loyihalar uchun umumiy
  static const String _buhApiEndpoint = 'http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws';

  /// Yangilash orasidagi minimal vaqt (soniyalarda)
  static const int refreshCooldownSeconds = 10;

  /// Kesh - tez kirish uchun
  final Map<String, ClientBalance> _cache = {};
  
  /// Oxirgi yangilash vaqtlari (INN bo'yicha)
  final Map<String, DateTime> _lastRefreshTimes = {};

  ClientBalanceService({
    required Dio dio,
    required ApiDatabaseService dbService,
    SharedPreferencesService? prefs, // Optional, kept for backward compatibility
  })  : _dio = dio,
        _dbService = dbService {
    _configureDio();
  }

  /// Dio konfiguratsiyasi
  void _configureDio() {
    // Alohida Dio instance uchun timeout sozlamalari
    // Asosiy Dio instance'ni o'zgartirmaymiz
  }

  /// ============================================================================
  /// Yangilash mumkinligini tekshirish
  /// ============================================================================
  /// 10 soniyalik cooldown tugaganmi yoki yo'qligini tekshiradi
  /// 
  /// [inn] - Mijoz INN raqami
  /// Returns: true agar yangilash mumkin bo'lsa
  bool canRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return true;
    
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    return elapsed >= refreshCooldownSeconds;
  }

  /// Keyingi yangilashgacha qolgan soniyalar
  int getSecondsUntilRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return 0;
    
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    final remaining = refreshCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// ============================================================================
  /// API'dan mijoz balansini olish
  /// ============================================================================
  /// SOAP so'rov yuborib, javobni parse qiladi va bazaga saqlaydi
  /// 
  /// [inn] - Mijoz INN raqami
  /// [clientCode] - Mijoz kodi (clients table bilan bog'lanish uchun)
  /// [projectName] - Loyiha nomi (masalan: "Evyap_-")
  /// [forceRefresh] - Cooldown'ni e'tiborsiz qoldirish
  /// 
  /// Returns: ClientBalance yoki null agar xatolik bo'lsa
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

    // SOAP so'rov yaratish
    final soapEnvelope = _buildSoapRequest(inn, projectName);

    try {
      final response = await _dio.post(
        _buhApiEndpoint,
        data: soapEnvelope,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction': '',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        // XML javobni parse qilish
        final clientBalance = _parseSoapResponse(response.data.toString(), inn, clientCode, projectName);
        
        if (clientBalance != null) {
          // Keshga saqlash
          _cache[inn] = clientBalance;
          
          // Yangilash vaqtini saqlash
          _lastRefreshTimes[inn] = DateTime.now();
          
          // Bazaga saqlash
          await saveClientBalance(clientBalance);
          
          if (kDebugMode) {
            print('ClientBalanceService: Successfully fetched balance for INN $inn: ${clientBalance.balance}');
          }
        }
        
        return clientBalance;
      } else {
        if (kDebugMode) {
          print('ClientBalanceService: HTTP error ${response.statusCode} for INN $inn');
        }
        return null;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: DioException for INN $inn: ${e.message}');
      }
      // Network xatolik - keshdan qaytarish
      return _cache[inn] ?? await getClientBalanceFromDb(inn);
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: Error fetching balance for INN $inn: $e');
      }
      return null;
    }
  }

  /// ============================================================================
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

  /// Shartnoma balansini parse qilish
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

  /// Buyurtma balansini parse qilish
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
  /// Keshdan balans olish
  /// ============================================================================
  ClientBalance? getClientBalanceFromCache(String inn) {
    return _cache[inn];
  }

  /// ============================================================================
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
  /// Balansni o'chirish
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
  /// Barcha balanslarni o'chirish
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
  /// Loyiha nomini serverdan olish
  /// ============================================================================
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
}
