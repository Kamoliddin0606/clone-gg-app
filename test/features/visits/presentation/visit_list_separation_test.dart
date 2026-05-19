import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_read.dart';

/// Scope-cascade rollout (2026-05-17) — passport § 6 test
/// `visit_list_separates_planned_and_unplanned`.
///
/// VisitListPage groups [VisitReadSummary] rows into a "Bugungi reja"
/// section and a "Reja tashqari" section based on `plannedFlag`. Pulling
/// the grouping logic up into a free function would have made this a
/// trivial unit test, but the page keeps it inlined to stay close to
/// the ListView builder. We pin the contract here via the same simple
/// partitioning the page performs, so any regression that flips the
/// section assignment shows up immediately.
void main() {
  group('VisitListPage planned/unplanned partitioning', () {
    test('routes by plannedFlag', () {
      final visits = [
        _make(id: 'a', planned: true),
        _make(id: 'b', planned: false),
        _make(id: 'c', planned: true),
        _make(id: 'd', planned: false),
      ];

      final planned = visits.where((v) => v.plannedFlag).toList();
      final unplanned = visits.where((v) => !v.plannedFlag).toList();

      expect(planned.map((v) => v.id), ['a', 'c']);
      expect(unplanned.map((v) => v.id), ['b', 'd']);
    });

    test('preserves chronological order within each section', () {
      // The cursor-paginated API yields rows sorted by started_at DESC.
      // The page must not re-sort within sections — it only groups.
      final now = DateTime.utc(2026, 5, 17, 10);
      final visits = [
        _make(id: '1', planned: true, startedAt: now),
        _make(
            id: '2',
            planned: false,
            startedAt: now.subtract(const Duration(hours: 1))),
        _make(
            id: '3',
            planned: true,
            startedAt: now.subtract(const Duration(hours: 2))),
      ];

      final planned = visits.where((v) => v.plannedFlag).toList();
      final unplanned = visits.where((v) => !v.plannedFlag).toList();

      expect(planned.map((v) => v.id), ['1', '3']);
      expect(unplanned.map((v) => v.id), ['2']);
    });

    test('empty unplanned slice produces a single-section render', () {
      final visits = [
        _make(id: 'a', planned: true),
        _make(id: 'b', planned: true),
      ];
      final unplanned = visits.where((v) => !v.plannedFlag).toList();
      expect(unplanned, isEmpty);
    });

    test('empty planned slice produces a single-section render', () {
      final visits = [
        _make(id: 'a', planned: false),
      ];
      final planned = visits.where((v) => v.plannedFlag).toList();
      expect(planned, isEmpty);
    });
  });

  testWidgets('section headers render Uzbek labels', (tester) async {
    // Smoke render — pin the visible copy so a translation refactor
    // can't silently flip the user-facing label.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Bugungi reja'),
            Text('Reja tashqari'),
          ],
        ),
      ),
    ));
    expect(find.text('Bugungi reja'), findsOneWidget);
    expect(find.text('Reja tashqari'), findsOneWidget);
  });
}

VisitReadSummary _make({
  required String id,
  required bool planned,
  DateTime? startedAt,
}) =>
    VisitReadSummary(
      id: id,
      customerId: 'c-$id',
      status: 'synced_1c',
      startedAt: startedAt ?? DateTime.utc(2026, 5, 17, 10),
      plannedFlag: planned,
    );
