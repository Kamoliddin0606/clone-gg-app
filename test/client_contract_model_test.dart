import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';

void main() {
  group('ClientContract Model Tests', () {
    test('ClientContract.fromMap creates correct instance', () {
      final map = {
        'code_contract': 'TEST001',
        'date_of_contract': '2023-01-15T00:00:00.000',
        'sum_of_contract': 100000.0,
        'term_of_contract': '2023-12-31T00:00:00.000',
        'type_contract': 'Предоплата 100 (%)',
        'numb_reference': '123456789',
        'numb_certificate': '987654321',
        'term_reference': '2023-01-01T00:00:00.000',
        'term_certificate': '2023-01-15T00:00:00.000',
        'numb_passport': 'AA1234567',
        'term_passport': '2025-01-15T00:00:00.000',
        'certificate_unlimited': 1,
        'code_district': '50',
        'name_district': 'Наманган',
        'code_project': '4',
        'code_client': '00-00012345',
        'active': 1,
        'status': 'Действует',
        'created_at': '2023-01-15T10:00:00.000',
        'updated_at': '2023-01-15T10:00:00.000',
      };

      final contract = ClientContract.fromMap(map);

      expect(contract.codeContract, 'TEST001');
      expect(contract.dateOfContract, DateTime(2023, 1, 15));
      expect(contract.sumOfContract, 100000.0);
      expect(contract.termOfContract, DateTime(2023, 12, 31));
      expect(contract.typeContract, 'Предоплата 100 (%)');
      expect(contract.numbReference, '123456789');
      expect(contract.numbCertificate, '987654321');
      expect(contract.termReference, DateTime(2023, 1, 1));
      expect(contract.termCertificate, DateTime(2023, 1, 15));
      expect(contract.numbPassport, 'AA1234567');
      expect(contract.termPassport, DateTime(2025, 1, 15));
      expect(contract.certificateUnlimited, 1);
      expect(contract.codeDistrict, '50');
      expect(contract.nameDistrict, 'Наманган');
      expect(contract.codeProject, '4');
      expect(contract.codeClient, '00-00012345');
      expect(contract.active, true);
      expect(contract.status, 'Действует');
      expect(contract.createdAt, DateTime(2023, 1, 15, 10));
      expect(contract.updatedAt, DateTime(2023, 1, 15, 10));
    });

    test('ClientContract.toMap returns correct map', () {
      final contract = ClientContract(
        codeContract: 'TEST001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        createdAt: DateTime(2023, 1, 15, 10),
        updatedAt: DateTime(2023, 1, 15, 10),
      );

      final map = contract.toMap();

      expect(map['code_contract'], 'TEST001');
      expect(map['date_of_contract'], '2023-01-15T00:00:00.000');
      expect(map['sum_of_contract'], 100000.0);
      expect(map['term_of_contract'], '2023-12-31T00:00:00.000');
      expect(map['type_contract'], 'Предоплата 100 (%)');
      expect(map['numb_reference'], '123456789');
      expect(map['numb_certificate'], '987654321');
      expect(map['term_reference'], '2023-01-01T00:00:00.000');
      expect(map['term_certificate'], '2023-01-15T00:00:00.000');
      expect(map['numb_passport'], 'AA1234567');
      expect(map['term_passport'], '2025-01-15T00:00:00.000');
      expect(map['certificate_unlimited'], 1);
      expect(map['code_district'], '50');
      expect(map['name_district'], 'Наманган');
      expect(map['code_project'], '4');
      expect(map['code_client'], '00-00012345');
      expect(map['active'], 1);
      expect(map['status'], 'Действует');
      expect(map['created_at'], '2023-01-15T10:00:00.000');
      expect(map['updated_at'], '2023-01-15T10:00:00.000');
    });

    test('ClientContract.copyWith creates modified copy', () {
      final original = ClientContract(
        codeContract: 'TEST001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
      );

      final modified = original.copyWith(
        sumOfContract: 150000.0,
        status: 'Не согласован',
        active: false,
      );

      expect(modified.codeContract, 'TEST001'); // unchanged
      expect(modified.sumOfContract, 150000.0); // changed
      expect(modified.status, 'Не согласован'); // changed
      expect(modified.active, false); // changed
      expect(modified.dateOfContract, DateTime(2023, 1, 15)); // unchanged
    });

    test('ClientContract equality works correctly', () {
      final contract1 = ClientContract(
        codeContract: 'TEST001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
      );

      final contract2 = ClientContract(
        codeContract: 'TEST001', // same code
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
      );

      final contract3 = ClientContract(
        codeContract: 'TEST002', // different code
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
      );

      expect(contract1 == contract2, true);
      expect(contract1 == contract3, false);
      expect(contract1.hashCode == contract2.hashCode, true);
      expect(contract1.hashCode == contract3.hashCode, false);
    });

    test('ClientContract toString works correctly', () {
      final contract = ClientContract(
        codeContract: 'TEST001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        termReference: DateTime(2023, 1, 1),
        termCertificate: DateTime(2023, 1, 15),
        numbPassport: 'AA1234567',
        termPassport: DateTime(2025, 1, 15),
        certificateUnlimited: 1,
        codeDistrict: '50',
        nameDistrict: 'Наманган',
        codeProject: '4',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
      );

      final toStringResult = contract.toString();
      expect(toStringResult, contains('TEST001'));
      expect(toStringResult, contains('Действует'));
      expect(toStringResult, contains('00-00012345'));
      expect(toStringResult, contains('true'));
    });

    test('ClientContract handles null values correctly', () {
      final map = {
        'code_contract': 'TEST001',
        'date_of_contract': null,
        'sum_of_contract': 0.0,
        'term_of_contract': null,
        'type_contract': null,
        'numb_reference': null,
        'numb_certificate': null,
        'term_reference': null,
        'term_certificate': null,
        'numb_passport': null,
        'term_passport': null,
        'certificate_unlimited': 0,
        'code_district': null,
        'name_district': null,
        'code_project': null,
        'code_client': '00-00012345',
        'active': 0,
        'status': 'Неизвестно',
      };

      final contract = ClientContract.fromMap(map);

      expect(contract.codeContract, 'TEST001');
      expect(contract.dateOfContract, null);
      expect(contract.sumOfContract, 0.0);
      expect(contract.termOfContract, null);
      expect(contract.typeContract, null);
      expect(contract.numbReference, null);
      expect(contract.numbCertificate, null);
      expect(contract.termReference, null);
      expect(contract.termCertificate, null);
      expect(contract.numbPassport, null);
      expect(contract.termPassport, null);
      expect(contract.certificateUnlimited, 0);
      expect(contract.codeDistrict, null);
      expect(contract.nameDistrict, null);
      expect(contract.codeProject, null);
      expect(contract.codeClient, '00-00012345');
      expect(contract.active, false);
      expect(contract.status, 'Неизвестно');
    });
  });
}