import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';
import 'package:gloria_marketing_flutter/src/core/version/presentation/version_gate_screen.dart';

VersionGateResponse buildPayload({
  VersionGateStatus status = VersionGateStatus.forceUpdate,
  String title = 'Title',
  String message = 'Message',
  String releaseNotes = 'Notes',
}) {
  return VersionGateResponse(
    status: status,
    app: 'sales',
    platform: 'android',
    currentVersion: '1.0.0',
    latestVersion: '1.1.0',
    minSupportedVersion: '0.9.0',
    storeUrl: 'https://play.google.com/store/apps/details?id=uz.gloriya.sales',
    releaseNotes: releaseNotes,
    title: title,
    message: message,
    canDismiss: false,
    checkedAt: DateTime.utc(2026, 5, 16),
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  testWidgets('VersionGateScreen renders server-driven title/message',
      (tester) async {
    await tester.pumpWidget(wrap(VersionGateScreen(
      payload: buildPayload(
        title: 'Update required',
        message: 'Please update to continue.',
        releaseNotes: '• Critical fixes',
      ),
    )));
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Please update to continue.'), findsOneWidget);
    expect(find.text('• Critical fixes'), findsOneWidget);
  });

  testWidgets('VersionGateScreen back navigation is blocked', (tester) async {
    await tester.pumpWidget(wrap(VersionGateScreen(
      payload: buildPayload(),
    )));
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });

  testWidgets('VersionGateScreen shows Retry on maintenance status',
      (tester) async {
    await tester.pumpWidget(wrap(VersionGateScreen(
      payload: buildPayload(status: VersionGateStatus.maintenance),
    )));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
  });

  testWidgets('VersionGateScreen shows Update on force_update status',
      (tester) async {
    await tester.pumpWidget(wrap(VersionGateScreen(
      payload: buildPayload(status: VersionGateStatus.forceUpdate),
    )));
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('Falls back to localized title when server payload is empty',
      (tester) async {
    await tester.pumpWidget(wrap(VersionGateScreen(
      payload: buildPayload(
        status: VersionGateStatus.blocked,
        title: '',
        message: '',
      ),
    )));
    expect(find.text('This version is blocked'), findsOneWidget);
  });
}
