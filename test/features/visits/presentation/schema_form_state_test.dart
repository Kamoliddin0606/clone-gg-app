import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/widgets/generic_schema_form/schema_form_state.dart';

/// SchemaFormState owns the entire payload mutation pipeline — leaf
/// widgets call write/appendToArray/removeFromArray and rely on the
/// state to materialise intermediate maps and lists. Bugs here would
/// surface as silent payload corruption in the envelope, so the basics
/// stay covered.
void main() {
  group('SchemaFormState', () {
    test('write at root path replaces whole map', () {
      final state = SchemaFormState();
      state.write([], {'foo': 1});
      expect(state.toJson(), {'foo': 1});
    });

    test('write creates nested map containers', () {
      final state = SchemaFormState();
      state.write(['answers', 'q1'], 'good');
      expect(state.toJson(), {
        'answers': {'q1': 'good'},
      });
    });

    test('write creates nested array containers with int segments', () {
      final state = SchemaFormState();
      state.write(['items', 0, 'name'], 'Alpha');
      state.write(['items', 1, 'name'], 'Beta');
      expect(state.toJson(), {
        'items': [
          {'name': 'Alpha'},
          {'name': 'Beta'},
        ],
      });
    });

    test('write null removes key from map', () {
      final state = SchemaFormState(initial: {'note': 'hi'});
      state.write(['note'], null);
      expect(state.toJson(), const <String, dynamic>{});
    });

    test('appendToArray creates list when missing', () {
      final state = SchemaFormState();
      state.appendToArray(['rows'], {'x': 1});
      expect(state.read(['rows']), [
        {'x': 1}
      ]);
    });

    test('appendToArray pushes to existing list', () {
      final state = SchemaFormState(initial: {
        'rows': [
          {'x': 1}
        ],
      });
      state.appendToArray(['rows'], {'x': 2});
      expect((state.read(['rows']) as List).length, 2);
    });

    test('removeFromArray drops requested index', () {
      final state = SchemaFormState(initial: {
        'rows': [1, 2, 3, 4],
      });
      state.removeFromArray(['rows'], 2);
      expect(state.read(['rows']), [1, 2, 4]);
    });

    test('toJson returns deep clone — caller mutation does not bleed back',
        () {
      final state = SchemaFormState();
      state.write(['answers'], {'q1': 'a'});
      final exported = state.toJson();
      (exported['answers'] as Map)['q1'] = 'mutated';
      expect(state.read(['answers', 'q1']), 'a');
    });

    test('notifies listeners on write', () {
      final state = SchemaFormState();
      var notifications = 0;
      state.addListener(() => notifications++);
      state.write(['x'], 1);
      state.write(['y'], 2);
      expect(notifications, 2);
    });
  });
}
