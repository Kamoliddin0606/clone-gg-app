/// ============================================================================
/// Client Balance Model Classes
/// ============================================================================
/// This file contains model classes for storing client balance data.
/// Data is retrieved via SOAP API from:
/// http://kit.gloriya.uz:5443/gloriya_buh2/gloriya_buh2.1cws?wsdl
/// 
/// Main classes:
/// - [ClientBalance] - General balance information
/// - [ClientBalanceByContract] - Balance by contract
/// - [ClientBalanceByOrder] - Balance by order
/// ============================================================================

import 'package:flutter/foundation.dart';

/// Parse a money/number value that may arrive as `num` (DB / local cache)
/// or as a Decimal string from the backend REST endpoint (DRF serialises
/// `DecimalField` as a String by default). Used by every `fromJson`
/// factory so a wire-format change doesn't surface as a runtime
/// `String is not a subtype of num?` cast error.
double? _parseDoubleField(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }
  return null;
}

/// Same shape as [_parseDoubleField] for integer-typed fields (e.g.
/// `overdue_days`). Backend currently emits ints, but xsi:nil collapses
/// to `null` and we accept stringified ints defensively.
int? _parseIntField(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }
  return null;
}

/// ============================================================================
/// ClientBalanceByContract - Balance data by contract
/// ============================================================================
/// Stores balance status for each contract.
/// Parsed from <m:ClientBalanceByContract> elements in API response.
class ClientBalanceByContract {
  /// Project name (e.g., "Проект ТМ EVYAP")
  final String projectName;
  
  /// Region name (e.g., "Tashkent")
  final String region;
  
  /// Client INN number
  final String taxId;
  
  /// Client name
  final String customerName;
  
  /// Contract code
  final String contractCode;
  
  /// Payment amount
  final double paymentAmount;
  
  /// Debt amount
  final double debtAmount;
  
  /// Contract ID
  final String contractId;

  const ClientBalanceByContract({
    required this.projectName,
    required this.region,
    required this.taxId,
    required this.customerName,
    required this.contractCode,
    required this.paymentAmount,
    required this.debtAmount,
    required this.contractId,
  });

  /// Factory constructor from XML element
  /// Parses <m:ClientBalanceByContract> element from SOAP response
  factory ClientBalanceByContract.fromXml(Map<String, String> xmlData) {
    return ClientBalanceByContract(
      projectName: xmlData['projectName'] ?? '',
      region: xmlData['region'] ?? '',
      taxId: xmlData['taxId'] ?? '',
      customerName: xmlData['customerName'] ?? '',
      contractCode: xmlData['contractCode'] ?? '',
      paymentAmount: double.tryParse(xmlData['paymentAmount'] ?? '0') ?? 0.0,
      debtAmount: double.tryParse(xmlData['debtAmount'] ?? '0') ?? 0.0,
      contractId: xmlData['contractId'] ?? '',
    );
  }

  /// Factory constructor from JSON (database OR backend REST response).
  /// Backend serialises Decimal columns as strings; SQLite returns them
  /// as `num`. [_parseDoubleField] covers both.
  factory ClientBalanceByContract.fromJson(Map<String, dynamic> json) {
    return ClientBalanceByContract(
      projectName: json['project_name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      taxId: json['tax_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      contractCode: json['contract_code']?.toString() ?? '',
      paymentAmount: _parseDoubleField(json['payment_amount']) ?? 0.0,
      debtAmount: _parseDoubleField(json['debt_amount']) ?? 0.0,
      contractId: json['contract_id']?.toString() ?? '',
    );
  }

  /// Convert to JSON (for writing to database)
  Map<String, dynamic> toJson() {
    return {
      'project_name': projectName,
      'region': region,
      'tax_id': taxId,
      'customer_name': customerName,
      'contract_code': contractCode,
      'payment_amount': paymentAmount,
      'debt_amount': debtAmount,
      'contract_id': contractId,
    };
  }

  /// Has debt by contract (debtAmount > 0 = debtor)
  /// Business logic: positive debtAmount = client is debtor
  bool get hasDebt => debtAmount > 0;

  /// Has overpayment by contract (debtAmount < 0 = overpayment)
  /// Business logic: negative debtAmount = client has overpaid
  bool get hasOverpayment => debtAmount < 0;

  /// Absolute debt amount (for formatting)
  double get absoluteDebtAmount => debtAmount.abs();

  @override
  String toString() {
    return 'ClientBalanceByContract(contractCode: $contractCode, paymentAmount: $paymentAmount, debtAmount: $debtAmount)';
  }
}

/// ============================================================================
/// ClientBalanceByOrder - Balance data by order
/// ============================================================================
/// Stores balance status for each order.
/// Parsed from <m:ClientBalanceByOrder> elements in API response.
class ClientBalanceByOrder {
  /// Project name
  final String projectName;
  
  /// Region name
  final String region;
  
  /// Client INN number
  final String taxId;
  
  /// Client name
  final String customerName;
  
  /// Contract code
  final String contractCode;
  
  /// Sales channel
  final String salesChannel;
  
  /// Order number
  final String orderNumber;
  
  /// Order date
  final DateTime? orderDate;
  
  /// Order amount
  final double orderAmount;
  
  /// Payment amount
  final double paymentAmount;
  
  /// Debt amount
  final double debtAmount;
  
  /// Payment status (Paid, Unpaid, Partial)
  final String status;
  
  /// Overdue days count
  final int overdueDays;
  
  /// Contract ID
  final String contractId;

  const ClientBalanceByOrder({
    required this.projectName,
    required this.region,
    required this.taxId,
    required this.customerName,
    required this.contractCode,
    required this.salesChannel,
    required this.orderNumber,
    this.orderDate,
    required this.orderAmount,
    required this.paymentAmount,
    required this.debtAmount,
    required this.status,
    required this.overdueDays,
    required this.contractId,
  });

  /// Factory constructor from XML element
  factory ClientBalanceByOrder.fromXml(Map<String, String> xmlData) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        if (kDebugMode) {
          print('ClientBalanceByOrder: Error parsing date: $dateStr - $e');
        }
        return null;
      }
    }

    return ClientBalanceByOrder(
      projectName: xmlData['projectName'] ?? '',
      region: xmlData['region'] ?? '',
      taxId: xmlData['taxId'] ?? '',
      customerName: xmlData['customerName'] ?? '',
      contractCode: xmlData['contractCode'] ?? '',
      salesChannel: xmlData['salesChannel'] ?? '',
      orderNumber: xmlData['orderNumber'] ?? '',
      orderDate: parseDate(xmlData['orderDate']),
      orderAmount: double.tryParse(xmlData['orderAmount'] ?? '0') ?? 0.0,
      paymentAmount: double.tryParse(xmlData['paymentAmount'] ?? '0') ?? 0.0,
      debtAmount: double.tryParse(xmlData['debtAmount'] ?? '0') ?? 0.0,
      status: xmlData['status'] ?? '',
      overdueDays: int.tryParse(xmlData['overdueDays'] ?? '0') ?? 0,
      contractId: xmlData['contractId'] ?? '',
    );
  }

  /// Factory constructor from JSON (for reading from database)
  factory ClientBalanceByOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return ClientBalanceByOrder(
      projectName: json['project_name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      taxId: json['tax_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      contractCode: json['contract_code']?.toString() ?? '',
      salesChannel: json['sales_channel']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      orderDate: parseDate(json['order_date']),
      orderAmount: _parseDoubleField(json['order_amount']) ?? 0.0,
      paymentAmount: _parseDoubleField(json['payment_amount']) ?? 0.0,
      debtAmount: _parseDoubleField(json['debt_amount']) ?? 0.0,
      status: json['status']?.toString() ?? '',
      overdueDays: _parseIntField(json['overdue_days']) ?? 0,
      contractId: json['contract_id']?.toString() ?? '',
    );
  }

  /// Convert to JSON (for writing to database)
  Map<String, dynamic> toJson() {
    return {
      'project_name': projectName,
      'region': region,
      'tax_id': taxId,
      'customer_name': customerName,
      'contract_code': contractCode,
      'sales_channel': salesChannel,
      'order_number': orderNumber,
      'order_date': orderDate?.toIso8601String(),
      'order_amount': orderAmount,
      'payment_amount': paymentAmount,
      'debt_amount': debtAmount,
      'status': status,
      'overdue_days': overdueDays,
      'contract_id': contractId,
    };
  }

  /// Payment status color mapping
  /// - Оплачено (paid) -> green
  /// - Частично (partial) -> yellow
  /// - Неоплачен (unpaid) -> red
  bool get isPaid => status == 'Оплачено';
  bool get isUnpaid => status == 'Неоплачен';
  
  /// Is partially paid - based on amounts logic
  /// If orderAmount > 0, paymentAmount > 0, and orderAmount > paymentAmount = partially paid
  bool get isPartiallyPaid => orderAmount > 0 && paymentAmount > 0 && orderAmount > paymentAmount;

  /// Is overdue
  bool get isOverdue => overdueDays > 0;

  /// Has debt by order (debtAmount > 0 = debtor)
  /// Business logic: positive debtAmount = client is debtor
  bool get hasDebt => debtAmount > 0;

  /// Is this an overpayment?
  /// Business logic: orderAmount empty/0, paymentAmount exists, debtAmount < 0 = overpayment
  bool get isOverpayment => (orderAmount == 0 || orderAmount.isNaN) && paymentAmount > 0 && debtAmount < 0;

  /// Absolute debt amount (for formatting)
  double get absoluteDebtAmount => debtAmount.abs();

  @override
  String toString() {
    return 'ClientBalanceByOrder(orderNumber: $orderNumber, orderAmount: $orderAmount, debtAmount: $debtAmount, status: $status)';
  }
}

/// ============================================================================
/// ClientBalance - Main client balance model
/// ============================================================================
/// Stores client's overall balance status and detailed information.
/// Parsed from <m:return> element in API response.
class ClientBalance {
  /// Client INN number (unique identifier)
  final String inn;
  
  /// Client code - for linking with clients table
  final String? clientCode;
  
  /// Total balance (positive = debtor, negative = overpayment)
  final double balance;
  
  /// Balance list by contracts
  final List<ClientBalanceByContract> contractBalances;
  
  /// Balance list by orders
  final List<ClientBalanceByOrder> orderBalances;
  
  /// Last update time (local: when app fetched data)
  final DateTime lastUpdated;
  
  /// Server-side update time (when accounting system updated balance data)
  /// Parsed from SOAP response updatedDateTime field
  final DateTime? serverDataUpdatedAt;
  
  /// Project name (used in API request)
  final String projectName;

  /// Project debt limit returned by backend (null = no limit).
  /// See Customer Balance Passport §2.2.
  final double? debtLimit;

  /// Currency for [debtLimit]. Default `"UZS"`.
  final String? debtLimitCurrency;

  /// Balance currency. Default `"UZS"`.
  final String? currency;

  /// Backend's authoritative block decision.
  /// `(debtLimit != null) AND (balance > debtLimit)`.
  final bool? blocked;

  /// Reason when [blocked] is true. Currently only `"debt_limit_exceeded"`.
  final String? blockReason;

  /// Cache freshness from backend: `"fresh"` | `"cache"` | `"stale"`.
  final String? source;

  /// Short SOAP error description when [source] == "stale".
  final String? lastError;

  const ClientBalance({
    required this.inn,
    this.clientCode,
    required this.balance,
    required this.contractBalances,
    required this.orderBalances,
    required this.lastUpdated,
    this.serverDataUpdatedAt,
    required this.projectName,
    this.debtLimit,
    this.debtLimitCurrency,
    this.currency,
    this.blocked,
    this.blockReason,
    this.source,
    this.lastError,
  });

  /// Create empty balance (no data received yet)
  factory ClientBalance.empty(String inn) {
    return ClientBalance(
      inn: inn,
      balance: 0.0,
      contractBalances: const [],
      orderBalances: const [],
      lastUpdated: DateTime.now(),
      serverDataUpdatedAt: null,
      projectName: '',
    );
  }

  /// Factory constructor from JSON (for reading from database)
  factory ClientBalance.fromJson(Map<String, dynamic> json) {
    // Parse server_data_updated_at with null safety
    DateTime? parseServerDataUpdatedAt() {
      final value = json['server_data_updated_at'];
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return ClientBalance(
      inn: json['inn']?.toString() ?? '',
      clientCode: json['client_code']?.toString(),
      balance: _parseDoubleField(json['balance']) ?? 0.0,
      contractBalances: (json['contract_balances'] as List<dynamic>?)
              ?.map((e) => ClientBalanceByContract.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      orderBalances: (json['order_balances'] as List<dynamic>?)
              ?.map((e) => ClientBalanceByOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
      serverDataUpdatedAt: parseServerDataUpdatedAt(),
      projectName: json['project_name']?.toString() ?? '',
      debtLimit: _parseDoubleField(json['debt_limit']),
      debtLimitCurrency: json['debt_limit_currency']?.toString(),
      currency: json['currency']?.toString(),
      blocked: json['blocked'] is bool ? json['blocked'] as bool : null,
      blockReason: json['block_reason']?.toString(),
      source: json['source']?.toString(),
      lastError: json['last_error']?.toString(),
    );
  }

  /// Convert to JSON (for writing to database)
  Map<String, dynamic> toJson() {
    return {
      'inn': inn,
      'client_code': clientCode,
      'balance': balance,
      'contract_balances': contractBalances.map((e) => e.toJson()).toList(),
      'order_balances': orderBalances.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'server_data_updated_at': serverDataUpdatedAt?.toIso8601String(),
      'project_name': projectName,
      'debt_limit': debtLimit,
      'debt_limit_currency': debtLimitCurrency,
      'currency': currency,
      'blocked': blocked,
      'block_reason': blockReason,
      'source': source,
      'last_error': lastError,
    };
  }

  /// Is client a debtor (positive balance = debtor)
  /// Business logic: positive value = client owes us
  bool get isDebtor => balance > 0;

  /// Has client overpaid (negative balance = overpayment)
  /// Business logic: negative value = client has overpaid
  bool get hasOverpayment => balance < 0;

  /// Is balance zero
  bool get isZeroBalance => balance == 0;

  /// Absolute balance value (for formatting)
  double get absoluteBalance => balance.abs();

  /// Total debt amount (only positive debtAmount - actual debt)
  /// Business logic: debtAmount > 0 = debt
  double get totalDebtAmount {
    return orderBalances
        .where((order) => order.debtAmount > 0)
        .fold(0.0, (sum, order) => sum + order.debtAmount);
  }

  /// Total overpayment amount (only negative debtAmount - overpayment)
  /// Business logic: debtAmount < 0 = overpayment
  double get totalOverpaymentAmount {
    return orderBalances
        .where((order) => order.debtAmount < 0)
        .fold(0.0, (sum, order) => sum + order.debtAmount.abs());
  }

  /// Total order amount (only actual orders)
  double get totalOrderAmount {
    return orderBalances
        .where((order) => order.orderAmount > 0)
        .fold(0.0, (sum, order) => sum + order.orderAmount);
  }

  /// Total payment amount
  double get totalPaymentAmount {
    return orderBalances.fold(0.0, (sum, order) => sum + order.paymentAmount);
  }

  /// Actual orders count (orderAmount > 0)
  int get actualOrdersCount {
    return orderBalances.where((o) => o.orderAmount > 0).length;
  }

  /// Overpayment rows count
  int get overpaymentRowsCount {
    return orderBalances.where((o) => o.isOverpayment).length;
  }

  /// Unpaid orders count (only actual orders)
  int get unpaidOrdersCount {
    return orderBalances.where((o) => o.orderAmount > 0 && o.isUnpaid).length;
  }

  /// Partially paid orders count (only actual orders)
  int get partiallyPaidOrdersCount {
    return orderBalances.where((o) => o.orderAmount > 0 && o.isPartiallyPaid).length;
  }

  /// Overdue orders count
  int get overdueOrdersCount {
    return orderBalances.where((o) => o.isOverdue).length;
  }

  /// Create copy (for updating)
  ClientBalance copyWith({
    String? inn,
    String? clientCode,
    double? balance,
    List<ClientBalanceByContract>? contractBalances,
    List<ClientBalanceByOrder>? orderBalances,
    DateTime? lastUpdated,
    DateTime? serverDataUpdatedAt,
    String? projectName,
    double? debtLimit,
    String? debtLimitCurrency,
    String? currency,
    bool? blocked,
    String? blockReason,
    String? source,
    String? lastError,
  }) {
    return ClientBalance(
      inn: inn ?? this.inn,
      clientCode: clientCode ?? this.clientCode,
      balance: balance ?? this.balance,
      contractBalances: contractBalances ?? this.contractBalances,
      orderBalances: orderBalances ?? this.orderBalances,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      serverDataUpdatedAt: serverDataUpdatedAt ?? this.serverDataUpdatedAt,
      projectName: projectName ?? this.projectName,
      debtLimit: debtLimit ?? this.debtLimit,
      debtLimitCurrency: debtLimitCurrency ?? this.debtLimitCurrency,
      currency: currency ?? this.currency,
      blocked: blocked ?? this.blocked,
      blockReason: blockReason ?? this.blockReason,
      source: source ?? this.source,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() {
    return 'ClientBalance(inn: $inn, balance: $balance, contracts: ${contractBalances.length}, orders: ${orderBalances.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientBalance && other.inn == inn;
  }

  @override
  int get hashCode => inn.hashCode;
}
