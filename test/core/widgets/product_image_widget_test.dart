import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image_page.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/widgets/product_image_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub repository that overrides the two public methods so the
/// widget's data path is controlled. The parent's Dio + TokenService
/// are never exercised because we replace `primaryForTarget` /
/// `listForTarget` outright. They still need to be resolvable from
/// `sl` for the parent constructor's late init.
class _StubRepo extends NewBackendImageRepository {
  _StubRepo({this.image});

  final UnifiedImage? image;

  @override
  Future<UnifiedImage?> primaryForTarget({
    required String targetType,
    required String targetCode1c,
    required String targetOrganizationId,
    CancelToken? cancelToken,
  }) async =>
      image;

  @override
  Future<UnifiedImagePage> listForTarget({
    required String targetType,
    required String targetCode1c,
    required String targetOrganizationId,
    String? cursor,
    int limit = 50,
    bool primaryOnly = false,
    CancelToken? cancelToken,
  }) async {
    final img = image;
    if (img == null) return UnifiedImagePage.empty;
    return UnifiedImagePage(images: [img], nextCursor: null);
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Future<void> _ensureBaseDeps() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  // The repo's parent constructor reads Dio + TokenService from `sl`
  // when no explicit values are passed. Register stand-ins so the
  // construction succeeds — the stub overrides the only methods that
  // would actually use them.
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton<Dio>(() => Dio());
  }
  if (!sl.isRegistered<SharedPreferencesService>()) {
    final svc = await SharedPreferencesService.getInstance();
    sl.registerSingleton<SharedPreferencesService>(svc);
  }
  if (!sl.isRegistered<TokenService>()) {
    sl.registerLazySingleton<TokenService>(
      () => TokenService(Dio(), sl<SharedPreferencesService>()),
    );
  }
}

void _registerRepoWith(UnifiedImage? image) {
  if (sl.isRegistered<NewBackendImageRepository>()) {
    sl.unregister<NewBackendImageRepository>();
  }
  sl.registerSingleton<NewBackendImageRepository>(_StubRepo(image: image));
  if (sl.isRegistered<AgentOrganizationContext>()) {
    sl.unregister<AgentOrganizationContext>();
  }
  sl.registerSingleton<AgentOrganizationContext>(
    AgentOrganizationContext.forTest(readGates: () => null),
  );
}

void main() {
  setUpAll(_ensureBaseDeps);

  setUp(() {
    _registerRepoWith(null);
  });

  testWidgets('shows error icon when productCode is empty', (tester) async {
    await tester.pumpWidget(_wrap(
      const ProductImageWidget(
        productCode: '',
        width: 80,
        height: 80,
        showShimmer: false,
      ),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('shows error icon when repo returns null', (tester) async {
    await tester.pumpWidget(_wrap(
      const ProductImageWidget(
        productCode: 'GLR0000123',
        width: 80,
        height: 80,
        showShimmer: false,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets(
    'renders the supplied placeholder during initial load',
    (tester) async {
      const placeholderKey = Key('custom-placeholder');
      await tester.pumpWidget(_wrap(
        const ProductImageWidget(
          productCode: 'GLR0000123',
          width: 80,
          height: 80,
          placeholder: SizedBox(
            key: placeholderKey,
            width: 80,
            height: 80,
          ),
        ),
      ));
      // Initial synchronous frame — the future hasn't resolved yet.
      expect(find.byKey(placeholderKey), findsOneWidget);
    },
  );

  testWidgets('rebuilds without exception when productCode changes',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const ProductImageWidget(
        productCode: 'first',
        width: 80,
        height: 80,
        showShimmer: false,
      ),
    ));
    await tester.pump();

    await tester.pumpWidget(_wrap(
      const ProductImageWidget(
        productCode: 'second',
        width: 80,
        height: 80,
        showShimmer: false,
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
