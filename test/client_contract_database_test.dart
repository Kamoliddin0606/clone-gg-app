import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ApiDatabaseService dbService;

  setUp(() async {
    dbService = ApiDatabaseService();
    // Clear all data before each test
    await dbService.clearAllData();
  });

  tearDown(() async {
    // Clean up after each test
    await dbService.clearAllData();
  });

  group('ClientContract Database Operations', () {
    test('saveClientContracts should save multiple contracts', () async {
      final contracts = [
        ClientContract(
          codeContract: 'CON001',
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
        ),
        ClientContract(
          codeContract: 'CON002',
          dateOfContract: DateTime(2023, 2, 20),
          sumOfContract: 150000.0,
          termOfContract: DateTime(2024, 2, 20),
          typeContract: 'Предоплата 50 (%)',
          numbReference: '987654321',
          numbCertificate: '123456789',
          termReference: DateTime(2023, 2, 15),
          termCertificate: DateTime(2023, 2, 20),
          numbPassport: 'BB7654321',
          termPassport: DateTime(2025, 2, 20),
          certificateUnlimited: 0,
          codeDistrict: '40',
          nameDistrict: 'Ташкент',
          codeProject: '3',
          codeClient: '00-00067890',
          active: false,
          status: 'Не согласован',
        ),
      ];

      await dbService.saveClientContracts(contracts);

      final savedContracts = await dbService.getClientContracts();
      expect(savedContracts.length, 2);
      expect(
        savedContracts.map((c) => c.codeContract),
        containsAll(['CON001', 'CON002']),
      );
      expect(
        savedContracts.map((c) => c.codeClient),
        containsAll(['00-00012345', '00-00067890']),
      );
    });

    test(
      'getClientContracts should return all contracts ordered by date',
      () async {
        final contracts = [
          ClientContract(
            codeContract: 'CON002',
            dateOfContract: DateTime(2023, 2, 20),
            sumOfContract: 150000.0,
            termOfContract: DateTime(2024, 2, 20),
            codeClient: '00-00067890',
            active: true,
            status: 'Действует',
            certificateUnlimited: 0,
          ),
          ClientContract(
            codeContract: 'CON001',
            dateOfContract: DateTime(2023, 1, 15),
            sumOfContract: 100000.0,
            termOfContract: DateTime(2023, 12, 31),
            codeClient: '00-00012345',
            active: true,
            status: 'Действует',
            certificateUnlimited: 0,
          ),
        ];

        await dbService.saveClientContracts(contracts);

        final savedContracts = await dbService.getClientContracts();
        expect(savedContracts.length, 2);
        expect(savedContracts[0].codeContract, 'CON002'); // Later date first
        expect(savedContracts[1].codeContract, 'CON001'); // Earlier date second
      },
    );

    test(
      'getClientContracts with clientCode filter should return filtered results',
      () async {
        final contracts = [
          ClientContract(
            codeContract: 'CON001',
            dateOfContract: DateTime(2023, 1, 15),
            sumOfContract: 100000.0,
            codeClient: '00-00012345',
            active: true,
            status: 'Действует',
            certificateUnlimited: 0,
          ),
          ClientContract(
            codeContract: 'CON002',
            dateOfContract: DateTime(2023, 2, 20),
            sumOfContract: 150000.0,
            codeClient: '00-00067890',
            active: true,
            status: 'Действует',
            certificateUnlimited: 0,
          ),
          ClientContract(
            codeContract: 'CON003',
            dateOfContract: DateTime(2023, 3, 10),
            sumOfContract: 200000.0,
            codeClient: '00-00012345',
            active: false,
            status: 'Не согласован',
            certificateUnlimited: 0,
          ),
        ];

        await dbService.saveClientContracts(contracts);

        final clientContracts = await dbService.getClientContracts(
          clientCode: '00-00012345',
        );
        expect(clientContracts.length, 2);
        expect(
          clientContracts.map((c) => c.codeContract),
          containsAll(['CON001', 'CON003']),
        );
      },
    );

    test(
      'getClientContracts with active filter should return filtered results',
      () async {
        final contracts = [
          ClientContract(
            codeContract: 'CON001',
            dateOfContract: DateTime(2023, 1, 15),
            sumOfContract: 100000.0,
            codeClient: '00-00012345',
            active: true,
            status: 'Действует',
            certificateUnlimited: 0,
          ),
          ClientContract(
            codeContract: 'CON002',
            dateOfContract: DateTime(2023, 2, 20),
            sumOfContract: 150000.0,
            codeClient: '00-00067890',
            active: false,
            status: 'Не согласован',
            certificateUnlimited: 0,
          ),
        ];

        await dbService.saveClientContracts(contracts);

        final activeContracts = await dbService.getClientContracts(
          active: true,
        );
        expect(activeContracts.length, 1);
        expect(activeContracts[0].codeContract, 'CON001');

        final inactiveContracts = await dbService.getClientContracts(
          active: false,
        );
        expect(inactiveContracts.length, 1);
        expect(inactiveContracts[0].codeContract, 'CON002');
      },
    );

    test('getClientContractByCode should return correct contract', () async {
      final contract = ClientContract(
        codeContract: 'CON001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        numbReference: '123456789',
        numbCertificate: '987654321',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      await dbService.saveClientContract(contract);

      final retrieved = await dbService.getClientContractByCode('CON001');
      expect(retrieved, isNotNull);
      expect(retrieved!.codeContract, 'CON001');
      expect(retrieved.sumOfContract, 100000.0);
      expect(retrieved.typeContract, 'Предоплата 100 (%)');
      expect(retrieved.codeClient, '00-00012345');
      expect(retrieved.active, true);
      expect(retrieved.status, 'Действует');
    });

    test(
      'getClientContractByCode should return null for non-existent code',
      () async {
        final retrieved = await dbService.getClientContractByCode(
          'NONEXISTENT',
        );
        expect(retrieved, isNull);
      },
    );

    test('saveClientContract should save single contract', () async {
      final contract = ClientContract(
        codeContract: 'CON001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      await dbService.saveClientContract(contract);

      final retrieved = await dbService.getClientContractByCode('CON001');
      expect(retrieved, isNotNull);
      expect(retrieved!.codeContract, 'CON001');
      expect(retrieved.sumOfContract, 100000.0);
      expect(retrieved.codeClient, '00-00012345');
    });

    test(
      'saveClientContract should replace existing contract with same code',
      () async {
        final contract1 = ClientContract(
          codeContract: 'CON001',
          sumOfContract: 100000.0,
          codeClient: '00-00012345',
          active: true,
          status: 'Действует',
          certificateUnlimited: 0,
        );

        final contract2 = ClientContract(
          codeContract: 'CON001',
          sumOfContract: 150000.0,
          codeClient: '00-00012345',
          active: false,
          status: 'Не согласован',
          certificateUnlimited: 0,
        );

        await dbService.saveClientContract(contract1);
        await dbService.saveClientContract(contract2);

        final retrieved = await dbService.getClientContractByCode('CON001');
        expect(retrieved, isNotNull);
        expect(retrieved!.sumOfContract, 150000.0);
        expect(retrieved.active, false);
        expect(retrieved.status, 'Не согласован');
      },
    );

    test('updateClientContract should update existing contract', () async {
      final original = ClientContract(
        codeContract: 'CON001',
        sumOfContract: 100000.0,
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      await dbService.saveClientContract(original);

      final updated = ClientContract(
        codeContract: 'CON001',
        sumOfContract: 150000.0,
        codeClient: '00-00012345',
        active: false,
        status: 'Не согласован',
        certificateUnlimited: 0,
      );

      await dbService.updateClientContract('CON001', updated);

      final retrieved = await dbService.getClientContractByCode('CON001');
      expect(retrieved, isNotNull);
      expect(retrieved!.sumOfContract, 150000.0);
      expect(retrieved.active, false);
      expect(retrieved.status, 'Не согласован');
    });

    test('deleteClientContract should remove contract', () async {
      final contract = ClientContract(
        codeContract: 'CON001',
        sumOfContract: 100000.0,
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      await dbService.saveClientContract(contract);

      // Verify it exists
      var retrieved = await dbService.getClientContractByCode('CON001');
      expect(retrieved, isNotNull);

      // Delete it
      await dbService.deleteClientContract('CON001');

      // Verify it's gone
      retrieved = await dbService.getClientContractByCode('CON001');
      expect(retrieved, isNull);
    });

    test('ClientContract model fromMap and toMap should be reversible', () {
      final original = ClientContract(
        codeContract: 'CON001',
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
        createdAt: DateTime(2023, 1, 15),
        updatedAt: DateTime(2023, 1, 15),
      );

      final map = original.toMap();
      final restored = ClientContract.fromMap(map);

      expect(restored.codeContract, original.codeContract);
      expect(restored.dateOfContract, original.dateOfContract);
      expect(restored.sumOfContract, original.sumOfContract);
      expect(restored.termOfContract, original.termOfContract);
      expect(restored.typeContract, original.typeContract);
      expect(restored.numbReference, original.numbReference);
      expect(restored.numbCertificate, original.numbCertificate);
      expect(restored.termReference, original.termReference);
      expect(restored.termCertificate, original.termCertificate);
      expect(restored.numbPassport, original.numbPassport);
      expect(restored.termPassport, original.termPassport);
      expect(restored.certificateUnlimited, original.certificateUnlimited);
      expect(restored.codeDistrict, original.codeDistrict);
      expect(restored.nameDistrict, original.nameDistrict);
      expect(restored.codeProject, original.codeProject);
      expect(restored.codeClient, original.codeClient);
      expect(restored.active, original.active);
      expect(restored.status, original.status);
      expect(
        restored.createdAt?.toIso8601String(),
        original.createdAt?.toIso8601String(),
      );
      expect(
        restored.updatedAt?.toIso8601String(),
        original.updatedAt?.toIso8601String(),
      );
    });

    test('ClientContract copyWith should work correctly', () {
      final original = ClientContract(
        codeContract: 'CON001',
        dateOfContract: DateTime(2023, 1, 15),
        sumOfContract: 100000.0,
        termOfContract: DateTime(2023, 12, 31),
        typeContract: 'Предоплата 100 (%)',
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
        createdAt: DateTime(2023, 1, 15),
        updatedAt: DateTime(2023, 1, 15),
      );

      final copied = original.copyWith(
        sumOfContract: 150000.0,
        status: 'Не согласован',
        active: false,
        updatedAt: DateTime(2023, 1, 16),
      );

      expect(copied.codeContract, 'CON001');
      expect(copied.sumOfContract, 150000.0);
      expect(copied.status, 'Не согласован');
      expect(copied.active, false);
      expect(copied.createdAt, DateTime(2023, 1, 15));
      expect(copied.updatedAt, DateTime(2023, 1, 16));
      expect(copied.dateOfContract, DateTime(2023, 1, 15)); // unchanged
      expect(copied.typeContract, 'Предоплата 100 (%)'); // unchanged
    });

    test('ClientContract equality should be based on codeContract', () {
      final contract1 = ClientContract(
        codeContract: 'CON001',
        sumOfContract: 100000.0,
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      final contract2 = ClientContract(
        codeContract: 'CON001',
        sumOfContract: 150000.0,
        codeClient: '00-00067890',
        active: false,
        status: 'Не согласован',
        certificateUnlimited: 0,
      );

      final contract3 = ClientContract(
        codeContract: 'CON002',
        sumOfContract: 100000.0,
        codeClient: '00-00012345',
        active: true,
        status: 'Действует',
        certificateUnlimited: 0,
      );

      expect(contract1 == contract2, true);
      expect(contract1 == contract3, false);
    });
  });
}
