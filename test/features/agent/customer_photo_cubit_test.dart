import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_photo_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_photo_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_photo_state.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_photo_service.dart';

UnifiedImage _row(String id, {bool ready = true, bool primary = false}) {
  return UnifiedImage(
    id: id,
    targetType: 'customer',
    targetId: 'cust-1',
    targetOrganizationId: 'org-1',
    targetCode1c: '',
    smallUrl: ready ? 'https://x/$id-s.webp' : null,
    mediumUrl: ready ? 'https://x/$id-m.webp' : null,
    largeUrl: ready ? 'https://x/$id-l.webp' : null,
    blurhash: '',
    width: 100,
    height: 100,
    isPrimary: primary,
    alt: '',
    order: 0,
  );
}

class _FakeRepo implements CustomerPhotoRepository {
  final List<UnifiedImage> photos;
  CustomerPhotoException? failNextWith;

  _FakeRepo(this.photos);

  @override
  Future<List<UnifiedImage>> list(String customerId,
      {String? status, bool? isPrimary, String? ordering}) async {
    return List<UnifiedImage>.from(photos);
  }

  @override
  Future<UnifiedImage> retrieve(String customerId, String photoId) async {
    return photos.firstWhere((p) => p.id == photoId);
  }

  @override
  Future<UnifiedImage> uploadOne({
    required String customerId,
    required File image,
    String alt = '',
    int order = 0,
    bool isPrimary = false,
  }) async {
    if (failNextWith != null) {
      final e = failNextWith!;
      failNextWith = null;
      throw e;
    }
    final added = _row('new-${photos.length + 1}', primary: isPrimary);
    photos.add(added);
    return added;
  }

  @override
  Future<List<UnifiedImage>> uploadBulk({
    required String customerId,
    required List<File> images,
  }) async {
    if (failNextWith != null) {
      final e = failNextWith!;
      failNextWith = null;
      throw e;
    }
    final added = <UnifiedImage>[];
    for (var i = 0; i < images.length; i++) {
      final a = _row('bulk-${photos.length + 1}');
      photos.add(a);
      added.add(a);
    }
    return added;
  }

  @override
  Future<UnifiedImage> patchMetadata({
    required String customerId,
    required String photoId,
    String? alt,
    int? order,
    bool? isPrimary,
  }) async {
    final i = photos.indexWhere((p) => p.id == photoId);
    final cur = photos[i];
    final updated = UnifiedImage(
      id: cur.id,
      targetType: cur.targetType,
      targetId: cur.targetId,
      targetOrganizationId: cur.targetOrganizationId,
      targetCode1c: cur.targetCode1c,
      smallUrl: cur.smallUrl,
      mediumUrl: cur.mediumUrl,
      largeUrl: cur.largeUrl,
      blurhash: cur.blurhash,
      width: cur.width,
      height: cur.height,
      isPrimary: isPrimary ?? cur.isPrimary,
      alt: alt ?? cur.alt,
      order: order ?? cur.order,
    );
    photos[i] = updated;
    return updated;
  }

  @override
  Future<UnifiedImage> replaceFile({
    required String customerId,
    required String photoId,
    required File image,
  }) async {
    return retrieve(customerId, photoId);
  }

  @override
  Future<void> delete({
    required String customerId,
    required String photoId,
  }) async {
    photos.removeWhere((p) => p.id == photoId);
  }

  @override
  Future<void> reprocess({
    required String customerId,
    required String photoId,
  }) async {
    throw const CustomerPhotoException(
      code: 'image_reprocess_not_supported',
      message: 'no original kept',
      statusCode: 400,
    );
  }

  // No-op for unused interface members.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CustomerPhotoCubit', () {
    test('load() transitions initial → loading → loaded', () async {
      final repo = _FakeRepo([_row('a'), _row('b')]);
      final service = CustomerPhotoService(repo: repo);
      final cubit = CustomerPhotoCubit(customerId: 'cust-1', service: service);

      final states = <CustomerPhotoStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));
      await cubit.load();
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(states.first, CustomerPhotoStatus.loading);
      expect(states.last, CustomerPhotoStatus.loaded);
      expect(cubit.state.photos, hasLength(2));
      expect(cubit.state.cap.current, 2);
      await cubit.close();
    });

    test('addOne() appends a row + refreshes the list', () async {
      final repo = _FakeRepo([_row('a')]);
      final cubit = CustomerPhotoCubit(
        customerId: 'cust-1',
        service: CustomerPhotoService(repo: repo),
      );
      await cubit.load();
      // Use a fake file path; the fake repo doesn't actually read it.
      await cubit.addOne(File('/tmp/fake.jpg'));
      expect(cubit.state.photos, hasLength(2));
      await cubit.close();
    });

    test('cap-exceeded surfaces as an errorCode + remembers max', () async {
      final repo = _FakeRepo([_row('a')]);
      repo.failNextWith = const CustomerPhotoException(
        code: 'customer_photo_limit_exceeded',
        message: 'cap',
        details: <String, dynamic>{
          'max': 10,
          'current': 10,
          'available': 0,
          'requested': 1,
        },
        statusCode: 409,
      );
      final cubit = CustomerPhotoCubit(
        customerId: 'cust-1',
        service: CustomerPhotoService(repo: repo),
      );
      await cubit.load();
      await cubit.addOne(File('/tmp/fake.jpg'));

      expect(cubit.state.errorCode, 'customer_photo_limit_exceeded');
      expect(cubit.state.cap.knownMax, 10);
      expect(cubit.state.cap.current, 10);
      await cubit.close();
    });

    test('delete() removes the row', () async {
      final repo = _FakeRepo([_row('a'), _row('b')]);
      final cubit = CustomerPhotoCubit(
        customerId: 'cust-1',
        service: CustomerPhotoService(repo: repo),
      );
      await cubit.load();
      await cubit.delete('a');
      expect(cubit.state.photos, hasLength(1));
      expect(cubit.state.photos.first.id, 'b');
      await cubit.close();
    });

    test('clearError wipes the pending error', () async {
      final repo = _FakeRepo([_row('a')]);
      repo.failNextWith = const CustomerPhotoException(
        code: 'customer_photo_limit_exceeded',
        message: 'cap',
        details: <String, dynamic>{
          'max': 10,
          'current': 10,
          'available': 0,
          'requested': 1,
        },
        statusCode: 409,
      );
      final cubit = CustomerPhotoCubit(
        customerId: 'cust-1',
        service: CustomerPhotoService(repo: repo),
      );
      await cubit.load();
      await cubit.addOne(File('/tmp/fake.jpg'));
      expect(cubit.state.errorCode, isNotNull);
      cubit.clearError();
      expect(cubit.state.errorCode, isNull);
      await cubit.close();
    });
  });
}
