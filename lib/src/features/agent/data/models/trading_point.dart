import 'package:flutter/foundation.dart';

class TradingPoint {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String ownerName;
  final String contactPerson;
  final String inn;
  final String status;
  final String lastVisitDate;
  final bool hasOrders;
  final bool hasContracts;
  final bool isVisited;
  final bool hasContract;
  final double latitude;
  final double longitude;
  final String region;
  final String district;
  final String signboard;
  final String referencePoint;
  final String responsiblePerson;
  final String responsiblePersonPhone;
  final String tradePointType;
  final double creditLimit;
  final double accumulatedCredit;
  final String codeRegion;

  // Yangi maydonlar: visit ma'lumotlari
  final bool visitToday;
  final int visitStepNumber;
  final String? plannedWeekDay;

  // Sales classifiers fields
  final String? channelCode;
  final String? tradingPointTypeCode;
  final String? clientClass;

  // Backend-first inversion: backend allocates a stable `code` (e.g.
  // `C-AB12CD34`) and `id` now mirrors that value. `code1c` is exposed
  // separately because the 1C SOAP code is no longer the local
  // identifier — it is a downstream value that may be empty during the
  // brief `pending_1c` window. `customerUuid` carries the backend UUID
  // needed by the photo flows (`/api/mobile/v2/customers/{uuid}/photos/`).
  // `codeBackend` holds the backend-allocated `C-XXXXXXXX` separately from
  // `code` so SOAP-sourced rows (where `code` == 1C kod) and backend-sourced
  // rows can coexist without overwriting one another.
  final String code;
  final String code1c;
  final String codeBackend;
  final String customerUuid;
  final String customerStatus;
  final String addressDelivery;
  final String director;
  final String mfo;
  final String bankAccount;
  final String salesChannel;

  const TradingPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.ownerName,
    required this.contactPerson,
    required this.inn,
    required this.status,
    required this.lastVisitDate,
    required this.hasOrders,
    required this.hasContracts,
    required this.isVisited,
    required this.hasContract,
    required this.latitude,
    required this.longitude,
    required this.region,
    required this.district,
    required this.signboard,
    required this.referencePoint,
    required this.responsiblePerson,
    required this.responsiblePersonPhone,
    required this.tradePointType,
    required this.creditLimit,
    required this.accumulatedCredit,
    required this.codeRegion,
    this.visitToday = false,
    this.visitStepNumber = 0,
    this.plannedWeekDay,
    this.channelCode,
    this.tradingPointTypeCode,
    this.clientClass,
    this.code = '',
    this.code1c = '',
    this.codeBackend = '',
    this.customerUuid = '',
    this.customerStatus = '',
    this.addressDelivery = '',
    this.director = '',
    this.mfo = '',
    this.bankAccount = '',
    this.salesChannel = '',
  });

  factory TradingPoint.fromJson(Map<String, dynamic> json) {
    // Helper function for safe double parsing
    double _safeParseDouble(dynamic value, String fieldName) {
      if (value == null) return 0.0;

      // Handle different types safely
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) return value.toDouble();

      // Log warning for unexpected types (only in debug mode to avoid spam)
      if (kDebugMode) {
        print('Warning: Unexpected type for $fieldName: ${value.runtimeType} = $value');
      }
      return 0.0;
    }

    return TradingPoint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      inn: json['inn']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastVisitDate: json['lastVisitDate']?.toString() ?? '',
      hasOrders: json['hasOrders'] == true,
      hasContracts: json['hasContracts'] == true,
      isVisited: json['isVisited'] == true,
      hasContract: json['hasContract'] == true,
      latitude: _safeParseDouble(json['latitude'], 'latitude'),
      longitude: _safeParseDouble(json['longitude'], 'longitude'),
      region: json['region']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      signboard: json['signboard']?.toString() ?? '',
      referencePoint: json['referencePoint']?.toString() ?? '',
      responsiblePerson: json['responsiblePerson']?.toString() ?? '',
      responsiblePersonPhone: json['responsiblePersonPhone']?.toString() ?? '',
      tradePointType: json['tradePointType']?.toString() ?? '',
      creditLimit: _safeParseDouble(json['creditLimit'], 'creditLimit'),
      accumulatedCredit: _safeParseDouble(json['accumulatedCredit'], 'accumulatedCredit'),
      codeRegion: json['codeRegion']?.toString() ?? '',
      visitToday: json['visitToday'] == true,
      visitStepNumber: json['visitStepNumber'] ?? 0,
      plannedWeekDay: json['plannedWeekDay']?.toString(),
      channelCode: json['channelCode']?.toString(),
      tradingPointTypeCode: json['tradingPointTypeCode']?.toString(),
      clientClass: json['clientClass']?.toString(),
      code: json['code']?.toString() ?? '',
      code1c: json['code1c']?.toString() ?? '',
      codeBackend: json['codeBackend']?.toString() ?? '',
      customerUuid: json['customerUuid']?.toString() ?? '',
      customerStatus: json['customerStatus']?.toString() ?? '',
      addressDelivery: json['addressDelivery']?.toString() ?? '',
      director: json['director']?.toString() ?? '',
      mfo: json['mfo']?.toString() ?? '',
      bankAccount: json['bankAccount']?.toString() ?? '',
      salesChannel: json['salesChannel']?.toString() ?? '',
    );
  }

  /// Parses the V2 `GET /api/mobile/v2/customers/{}/` row shape
  /// (snake_case DRF serializer output). Distinct from [fromJson]
  /// which parses the SOAP-derived local-cache shape.
  ///
  /// Local identifier (`id`) is the backend-allocated `code`
  /// (`C-XXXXXXXX`) — stable across the brief `pending_1c` window
  /// before `code_1c` is populated. The PATCH endpoints accept either
  /// the backend UUID or the `code` as `{customer_id}`.
  factory TradingPoint.fromBackendJson(Map<String, dynamic> json) {
    double parseDouble(Object? value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String readString(String key) {
      final value = json[key];
      return value is String ? value : (value?.toString() ?? '');
    }

    final backendCode = readString('code');
    final code1c = readString('code_1c');
    final uuid = readString('id');
    // Local `code` mirrors the 1C reference when present so SOAP-keyed
    // lookups (balance, orders) keep working; falls back to the backend
    // code during the brief `pending_1c` window, then to the UUID.
    final localCode = code1c.isNotEmpty
        ? code1c
        : (backendCode.isNotEmpty ? backendCode : uuid);

    return TradingPoint(
      id: localCode,
      name: readString('name'),
      address: readString('address'),
      phone: readString('phone'),
      ownerName: '',
      contactPerson: readString('contact_person'),
      inn: readString('inn'),
      status: json['is_active'] == false ? 'inactive' : 'active',
      lastVisitDate: '',
      hasOrders: false,
      hasContracts: false,
      isVisited: false,
      hasContract: false,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      region: '',
      district: '',
      signboard: readString('signboard'),
      referencePoint: readString('reference_point'),
      responsiblePerson: '',
      responsiblePersonPhone: readString('responsible_person_phone'),
      tradePointType: readString('trade_point_type'),
      creditLimit: 0.0,
      accumulatedCredit: 0.0,
      codeRegion: readString('code_region'),
      code: localCode,
      code1c: code1c,
      codeBackend: backendCode,
      customerUuid: uuid,
      customerStatus: readString('status'),
      addressDelivery: readString('address_delivery'),
      director: readString('director'),
      mfo: readString('mfo'),
      bankAccount: readString('bank_account'),
      salesChannel: readString('sales_channel'),
      clientClass: readString('client_class').isEmpty
          ? null
          : readString('client_class'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'ownerName': ownerName,
      'contactPerson': contactPerson,
      'inn': inn,
      'status': status,
      'lastVisitDate': lastVisitDate,
      'hasOrders': hasOrders,
      'hasContracts': hasContracts,
      'isVisited': isVisited,
      'hasContract': hasContract,
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'district': district,
      'signboard': signboard,
      'referencePoint': referencePoint,
      'responsiblePerson': responsiblePerson,
      'responsiblePersonPhone': responsiblePersonPhone,
      'tradePointType': tradePointType,
      'creditLimit': creditLimit,
      'accumulatedCredit': accumulatedCredit,
      'codeRegion': codeRegion,
      'visitToday': visitToday,
      'visitStepNumber': visitStepNumber,
      'plannedWeekDay': plannedWeekDay,
      'channelCode': channelCode,
      'tradingPointTypeCode': tradingPointTypeCode,
      'clientClass': clientClass,
      'code': code,
      'code1c': code1c,
      'codeBackend': codeBackend,
      'customerUuid': customerUuid,
      'customerStatus': customerStatus,
      'addressDelivery': addressDelivery,
      'director': director,
      'mfo': mfo,
      'bankAccount': bankAccount,
      'salesChannel': salesChannel,
    };
  }

  TradingPoint copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? ownerName,
    String? contactPerson,
    String? inn,
    String? status,
    String? lastVisitDate,
    bool? hasOrders,
    bool? hasContracts,
    bool? isVisited,
    bool? hasContract,
    double? latitude,
    double? longitude,
    String? region,
    String? district,
    String? signboard,
    String? referencePoint,
    String? responsiblePerson,
    String? responsiblePersonPhone,
    String? tradePointType,
    double? creditLimit,
    double? accumulatedCredit,
    String? codeRegion,
    bool? visitToday,
    int? visitStepNumber,
    String? plannedWeekDay,
    String? channelCode,
    String? tradingPointTypeCode,
    String? clientClass,
    String? code,
    String? code1c,
    String? codeBackend,
    String? customerUuid,
    String? customerStatus,
    String? addressDelivery,
    String? director,
    String? mfo,
    String? bankAccount,
    String? salesChannel,
  }) {
    return TradingPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      ownerName: ownerName ?? this.ownerName,
      contactPerson: contactPerson ?? this.contactPerson,
      inn: inn ?? this.inn,
      status: status ?? this.status,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      hasOrders: hasOrders ?? this.hasOrders,
      hasContracts: hasContracts ?? this.hasContracts,
      isVisited: isVisited ?? this.isVisited,
      hasContract: hasContract ?? this.hasContract,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      district: district ?? this.district,
      signboard: signboard ?? this.signboard,
      referencePoint: referencePoint ?? this.referencePoint,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      responsiblePersonPhone: responsiblePersonPhone ?? this.responsiblePersonPhone,
      tradePointType: tradePointType ?? this.tradePointType,
      creditLimit: creditLimit ?? this.creditLimit,
      accumulatedCredit: accumulatedCredit ?? this.accumulatedCredit,
      codeRegion: codeRegion ?? this.codeRegion,
      visitToday: visitToday ?? this.visitToday,
      visitStepNumber: visitStepNumber ?? this.visitStepNumber,
      plannedWeekDay: plannedWeekDay ?? this.plannedWeekDay,
      channelCode: channelCode ?? this.channelCode,
      tradingPointTypeCode: tradingPointTypeCode ?? this.tradingPointTypeCode,
      clientClass: clientClass ?? this.clientClass,
      code: code ?? this.code,
      code1c: code1c ?? this.code1c,
      codeBackend: codeBackend ?? this.codeBackend,
      customerUuid: customerUuid ?? this.customerUuid,
      customerStatus: customerStatus ?? this.customerStatus,
      addressDelivery: addressDelivery ?? this.addressDelivery,
      director: director ?? this.director,
      mfo: mfo ?? this.mfo,
      bankAccount: bankAccount ?? this.bankAccount,
      salesChannel: salesChannel ?? this.salesChannel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradingPoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TradingPoint(id: $id, name: $name, address: $address, visitToday: $visitToday, visitStepNumber: $visitStepNumber)';
  }
}
