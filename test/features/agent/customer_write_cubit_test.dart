import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_write_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_write_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_write_state.dart';

TradingPoint _row({String id = 'cust-1', String name = 'Mahalla'}) {
  return TradingPoint(
    id: id,
    name: name,
    address: '',
    phone: '',
    ownerName: '',
    contactPerson: '',
    inn: '',
    status: 'active',
    lastVisitDate: '',
    hasOrders: false,
    hasContracts: false,
    isVisited: false,
    hasContract: false,
    latitude: 0,
    longitude: 0,
    region: '',
    district: '',
    signboard: '',
    referencePoint: '',
    responsiblePerson: '',
    responsiblePersonPhone: '',
    tradePointType: '',
    creditLimit: 0,
    accumulatedCredit: 0,
    codeRegion: '',
  );
}

/// Programmable fake — selectively overrides the three repo methods.
class _FakeRepo implements CustomerWriteRepository {
  TradingPoint? returnRow;
  Object? throwError;
  String? lastAction;
  Map<String, dynamic>? lastArgs;

  @override
  Future<TradingPoint> create({
    required String code1c,
    required String name,
    String inn = '',
    String phone = '',
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    lastAction = 'create';
    lastArgs = <String, dynamic>{
      'code1c': code1c,
      'name': name,
      'inn': inn,
    };
    if (throwError != null) throw throwError!;
    return returnRow ?? _row();
  }

  @override
  Future<TradingPoint> updateProfile({
    required String customerId,
    String? name,
    String? inn,
    String? phone,
    String? address,
  }) async {
    lastAction = 'updateProfile';
    lastArgs = <String, dynamic>{
      'customerId': customerId,
      'name': name,
    };
    if (throwError != null) throw throwError!;
    return returnRow ?? _row(id: customerId, name: name ?? '');
  }

  @override
  Future<TradingPoint> updateCoordinates({
    required String customerId,
    required double latitude,
    required double longitude,
  }) async {
    lastAction = 'updateCoordinates';
    lastArgs = <String, dynamic>{
      'customerId': customerId,
      'lat': latitude,
      'lng': longitude,
    };
    if (throwError != null) throw throwError!;
    return returnRow ?? _row(id: customerId);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerWriteCubit', () {
    late _FakeRepo repo;
    late CustomerWriteCubit cubit;

    setUp(() {
      repo = _FakeRepo();
      cubit = CustomerWriteCubit(repo: repo);
    });

    tearDown(() => cubit.close());

    test('create: initial → submitting → success', () async {
      repo.returnRow = _row(id: 'NEW-1', name: 'Mahalla');
      final states = <CustomerWriteState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.create(code1c: '00-NEW-1', name: 'Mahalla');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states.first.status, CustomerWriteStatus.submitting);
      expect(states.first.action, CustomerWriteAction.create);
      expect(states.last.status, CustomerWriteStatus.success);
      expect(states.last.lastResult?.id, 'NEW-1');
      expect(repo.lastAction, 'create');
    });

    test('updateProfile: initial → submitting → success', () async {
      repo.returnRow = _row(id: 'cust-9', name: 'New Name');
      await cubit.updateProfile(customerId: 'cust-9', name: 'New Name');

      expect(cubit.state.status, CustomerWriteStatus.success);
      expect(cubit.state.action, CustomerWriteAction.updateProfile);
      expect(cubit.state.lastResult?.id, 'cust-9');
    });

    test('updateCoordinates → success', () async {
      repo.returnRow = _row(id: 'cust-3');
      await cubit.updateCoordinates(
        customerId: 'cust-3',
        latitude: 41.311081,
        longitude: 69.240562,
      );

      expect(cubit.state.status, CustomerWriteStatus.success);
      expect(cubit.state.action, CustomerWriteAction.updateCoordinates);
      expect(repo.lastArgs!['lat'], 41.311081);
      expect(repo.lastArgs!['lng'], 69.240562);
    });

    test('typed CustomerWriteException is forwarded as state error',
        () async {
      repo.throwError = const CustomerWriteException(
        code: 'invalid_coordinates',
        message: 'oob',
        statusCode: 400,
      );
      await cubit.updateCoordinates(
        customerId: 'cust-9',
        latitude: 999,
        longitude: 0,
      );

      expect(cubit.state.status, CustomerWriteStatus.error);
      expect(cubit.state.errorCode, 'invalid_coordinates');
    });

    test('unknown errors collapse to unknown_error', () async {
      repo.throwError = Exception('boom');
      await cubit.create(code1c: '00-X', name: 'X');

      expect(cubit.state.status, CustomerWriteStatus.error);
      expect(cubit.state.errorCode, 'unknown_error');
    });

    test('concurrent submit short-circuits with in_flight error',
        () async {
      // Stage a slow create so the second call sees submitting state.
      final completer = Completer<TradingPoint>();
      final slowRepo = _SlowRepo(completer.future);
      final slowCubit = CustomerWriteCubit(repo: slowRepo);

      final first = slowCubit.create(code1c: '00-A', name: 'A');
      // Yield so the cubit emits submitting before the second call.
      await Future<void>.delayed(Duration.zero);
      await slowCubit.create(code1c: '00-B', name: 'B');

      expect(slowCubit.state.status, CustomerWriteStatus.error);
      expect(slowCubit.state.errorCode, 'in_flight');

      completer.complete(_row());
      await first;
      await slowCubit.close();
    });
  });
}

class _SlowRepo implements CustomerWriteRepository {
  final Future<TradingPoint> _result;
  _SlowRepo(this._result);

  @override
  Future<TradingPoint> create({
    required String code1c,
    required String name,
    String inn = '',
    String phone = '',
    String address = '',
    double? latitude,
    double? longitude,
  }) =>
      _result;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
