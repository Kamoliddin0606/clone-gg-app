/// Model for organization certificate data extracted from AI scanning
/// Contains all fields that can be extracted from a business certificate image
class ScannedDocumentData {
  final String? organizationName;
  final String? inn; // STIR - Tax Identification Number
  final String? directorName;
  final String? address;
  final String? phoneNumber;
  final String? bankAccount;
  final String? mfo; // Bank MFO code
  final String? oked; // Economic activity code
  final String? registrationNumber;
  final String? registrationDate;
  final double confidence; // AI confidence score (0.0 - 1.0)

  const ScannedDocumentData({
    this.organizationName,
    this.inn,
    this.directorName,
    this.address,
    this.phoneNumber,
    this.bankAccount,
    this.mfo,
    this.oked,
    this.registrationNumber,
    this.registrationDate,
    this.confidence = 0.0,
  });

  /// Create instance from AI response JSON
  factory ScannedDocumentData.fromJson(Map<String, dynamic> json) {
    return ScannedDocumentData(
      organizationName: _cleanString(json['organizationName'] ?? json['companyName'] ?? json['name']),
      inn: _cleanString(json['inn'] ?? json['stir'] ?? json['tin']),
      directorName: _cleanString(json['directorName'] ?? json['director'] ?? json['ceo']),
      address: _cleanString(json['address'] ?? json['legalAddress']),
      phoneNumber: _cleanString(json['phoneNumber'] ?? json['phone'] ?? json['tel']),
      bankAccount: _cleanString(json['bankAccount'] ?? json['accountNumber']),
      mfo: _cleanString(json['mfo'] ?? json['bankMfo']),
      oked: _cleanString(json['oked'] ?? json['activityCode']),
      registrationNumber: _cleanString(json['registrationNumber'] ?? json['regNumber']),
      registrationDate: _cleanString(json['registrationDate'] ?? json['regDate']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }

  /// Clean and normalize string values
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'organizationName': organizationName,
      'inn': inn,
      'directorName': directorName,
      'address': address,
      'phoneNumber': phoneNumber,
      'bankAccount': bankAccount,
      'mfo': mfo,
      'oked': oked,
      'registrationNumber': registrationNumber,
      'registrationDate': registrationDate,
      'confidence': confidence,
    };
  }

  /// Check if document has INN/STIR for Faktura verification
  bool get hasInn => inn != null && inn!.isNotEmpty;

  /// Check if document has any useful data
  bool get hasData =>
      organizationName != null ||
      inn != null ||
      directorName != null ||
      address != null;

  /// Get count of extracted fields
  int get extractedFieldCount {
    int count = 0;
    if (organizationName != null) count++;
    if (inn != null) count++;
    if (directorName != null) count++;
    if (address != null) count++;
    if (phoneNumber != null) count++;
    if (bankAccount != null) count++;
    if (mfo != null) count++;
    if (oked != null) count++;
    if (registrationNumber != null) count++;
    if (registrationDate != null) count++;
    return count;
  }

  /// Create a copy with updated fields
  ScannedDocumentData copyWith({
    String? organizationName,
    String? inn,
    String? directorName,
    String? address,
    String? phoneNumber,
    String? bankAccount,
    String? mfo,
    String? oked,
    String? registrationNumber,
    String? registrationDate,
    double? confidence,
  }) {
    return ScannedDocumentData(
      organizationName: organizationName ?? this.organizationName,
      inn: inn ?? this.inn,
      directorName: directorName ?? this.directorName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bankAccount: bankAccount ?? this.bankAccount,
      mfo: mfo ?? this.mfo,
      oked: oked ?? this.oked,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'ScannedDocumentData(name: $organizationName, inn: $inn, director: $directorName, fields: $extractedFieldCount)';
  }
}
