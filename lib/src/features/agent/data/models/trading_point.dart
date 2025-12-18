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

  final String? photoUrl;

  // Yangi maydonlar: visit ma'lumotlari
  final bool visitToday;
  final int visitStepNumber;
  final String? plannedWeekDay;

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
    this.photoUrl,
    this.visitToday = false,
    this.visitStepNumber = 0,
    this.plannedWeekDay,
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
      photoUrl: json['photoUrl']?.toString(),
      visitToday: json['visitToday'] == true,
      visitStepNumber: json['visitStepNumber'] ?? 0,
      plannedWeekDay: json['plannedWeekDay']?.toString(),
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