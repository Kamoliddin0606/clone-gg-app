/// Model for Faktura.uz company details response
class FakturaCompanyDetails {
  final String companyInn;
  final String? pinfl;
  final String companyName;
  final String companyAddress;
  final String regionCode;
  final String region;
  final String districtCode;
  final String district;
  final String? phoneNumber;
  final String? email;
  final String? vatCode;
  final String? specialAccount;
  final List<BankAccount> accounts;
  final String? directorInn;
  final String? directorPinfl;
  final String? directorName;
  final String? accountant;
  final String? oked;
  final String? taxGap;
  final String? taxPayerTypeName;
  final List<Branch> branches;

  FakturaCompanyDetails({
    required this.companyInn,
    this.pinfl,
    required this.companyName,
    required this.companyAddress,
    required this.regionCode,
    required this.region,
    required this.districtCode,
    required this.district,
    this.phoneNumber,
    this.email,
    this.vatCode,
    this.specialAccount,
    required this.accounts,
    this.directorInn,
    this.directorPinfl,
    this.directorName,
    this.accountant,
    this.oked,
    this.taxGap,
    this.taxPayerTypeName,
    required this.branches,
  });

  factory FakturaCompanyDetails.fromJson(Map<String, dynamic> json) {
    return FakturaCompanyDetails(
      companyInn: json['CompanyInn'] as String,
      pinfl: json['Pinfl'] as String?,
      companyName: json['CompanyName'] as String,
      companyAddress: json['CompanyAddress'] as String,
      regionCode: json['RegionCode'] as String,
      region: json['Region'] as String,
      districtCode: json['DistrictCode'] as String,
      district: json['District'] as String,
      phoneNumber: json['PhoneNumber'] as String?,
      email: json['Email'] as String?,
      vatCode: json['VatCode'] as String?,
      specialAccount: json['SpecialAccount'] as String?,
      accounts: (json['Accounts'] as List<dynamic>?)
              ?.map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      directorInn: json['DirectorInn'] as String?,
      directorPinfl: json['DirectorPinfl'] as String?,
      directorName: json['DirectorName'] as String?,
      accountant: json['Accountant'] as String?,
      oked: json['Oked'] as String?,
      taxGap: json['TaxGap'] as String?,
      taxPayerTypeName: json['TaxPayerTypeName'] as String?,
      branches: (json['Branches'] as List<dynamic>?)
              ?.map((e) => Branch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CompanyInn': companyInn,
      'Pinfl': pinfl,
      'CompanyName': companyName,
      'CompanyAddress': companyAddress,
      'RegionCode': regionCode,
      'Region': region,
      'DistrictCode': districtCode,
      'District': district,
      'PhoneNumber': phoneNumber,
      'Email': email,
      'VatCode': vatCode,
      'SpecialAccount': specialAccount,
      'Accounts': accounts.map((e) => e.toJson()).toList(),
      'DirectorInn': directorInn,
      'DirectorPinfl': directorPinfl,
      'DirectorName': directorName,
      'Accountant': accountant,
      'Oked': oked,
      'TaxGap': taxGap,
      'TaxPayerTypeName': taxPayerTypeName,
      'Branches': branches.map((e) => e.toJson()).toList(),
    };
  }

  /// Get formatted full address combining region, district, and company address
  String getFullAddress() {
    final parts = <String>[];
    
    if (region.isNotEmpty) parts.add(region);
    if (district.isNotEmpty) parts.add(district);
    if (companyAddress.trim().isNotEmpty) parts.add(companyAddress.trim());
    
    return parts.join(', ');
  }

  /// Get primary bank account
  BankAccount? getPrimaryAccount() {
    try {
      return accounts.firstWhere((account) => account.isPrimary);
    } catch (e) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }
}

/// Bank account information
class BankAccount {
  final String bankName;
  final String bankMfo;
  final String accountCode;
  final bool isPrimary;

  BankAccount({
    required this.bankName,
    required this.bankMfo,
    required this.accountCode,
    required this.isPrimary,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      bankName: json['BankName'] as String,
      bankMfo: json['BankMfo'] as String,
      accountCode: json['AccountCode'] as String,
      isPrimary: json['IsPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BankName': bankName,
      'BankMfo': bankMfo,
      'AccountCode': accountCode,
      'IsPrimary': isPrimary,
    };
  }
}

/// Branch information
class Branch {
  final int id;
  final String name;
  final String code;

  Branch({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['Id'] as int,
      name: json['Name'] as String,
      code: json['Code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Code': code,
    };
  }
}
