import 'package:flutter/foundation.dart';

/// Mutable payload backing a [SchemaFormRenderer] tree.
///
/// Stores values addressed by JSON-pointer-like paths (e.g. `["answers", 0,
/// "value"]`). Wrapped in a ChangeNotifier so individual field widgets can
/// rebuild without their parent owning a giant nested setState.
///
/// The engine never mutates the schema; it only writes user input into
/// [_root]. Callers serialise the result via [toJson] when the task is
/// completed.
class SchemaFormState extends ChangeNotifier {
  SchemaFormState({Map<String, dynamic>? initial})
      : _root = _deepClone(initial ?? const {});

  Map<String, dynamic> _root;

  Map<String, dynamic> toJson() => _deepClone(_root);

  /// Read a value at [path]. Returns `null` when any segment is missing —
  /// callers use this to decide whether to show a placeholder.
  Object? read(List<Object> path) {
    Object? cursor = _root;
    for (final segment in path) {
      if (cursor is Map && segment is String) {
        cursor = cursor[segment];
      } else if (cursor is List && segment is int) {
        if (segment < 0 || segment >= cursor.length) return null;
        cursor = cursor[segment];
      } else {
        return null;
      }
    }
    return cursor;
  }

  /// Write [value] at [path], creating any missing intermediate
  /// containers. Numeric path segments materialise as `List<dynamic>`;
  /// strings as `Map<String, dynamic>`. Notifies listeners once.
  void write(List<Object> path, Object? value) {
    if (path.isEmpty) {
      if (value is Map<String, dynamic>) {
        _root = _deepClone(value);
        notifyListeners();
      }
      return;
    }
    _writeRecursive(_root, path, 0, value);
    notifyListeners();
  }

  void _writeRecursive(
    Object container,
    List<Object> path,
    int index,
    Object? value,
  ) {
    final segment = path[index];
    final isLast = index == path.length - 1;
    if (container is Map<String, dynamic> && segment is String) {
      if (isLast) {
        if (value == null) {
          container.remove(segment);
        } else {
          container[segment] = value;
        }
        return;
      }
      final next = container[segment];
      final nextSegment = path[index + 1];
      if (next is Map<String, dynamic>) {
        _writeRecursive(next, path, index + 1, value);
      } else if (next is List<dynamic>) {
        _writeRecursive(next, path, index + 1, value);
      } else {
        final created = nextSegment is int
            ? <dynamic>[]
            : <String, dynamic>{};
        container[segment] = created;
        _writeRecursive(created, path, index + 1, value);
      }
    } else if (container is List<dynamic> && segment is int) {
      while (container.length <= segment) {
        container.add(null);
      }
      if (isLast) {
        container[segment] = value;
        return;
      }
      final next = container[segment];
      final nextSegment = path[index + 1];
      if (next is Map<String, dynamic> || next is List<dynamic>) {
        _writeRecursive(next as Object, path, index + 1, value);
      } else {
        final created = nextSegment is int
            ? <dynamic>[]
            : <String, dynamic>{};
        container[segment] = created;
        _writeRecursive(created, path, index + 1, value);
      }
    }
  }

  /// Append [item] to the array at [path]. Used by `array` field's "add"
  /// button. Creates the array if it doesn't exist.
  void appendToArray(List<Object> path, Object? item) {
    final existing = read(path);
    if (existing is List) {
      existing.add(item);
      notifyListeners();
      return;
    }
    write(path, [item]);
  }

  /// Remove the [index]th element of the array at [path].
  void removeFromArray(List<Object> path, int index) {
    final existing = read(path);
    if (existing is List && index >= 0 && index < existing.length) {
      existing.removeAt(index);
      notifyListeners();
    }
  }

  static Map<String, dynamic> _deepClone(Map<String, dynamic> source) {
    return _clone(source) as Map<String, dynamic>;
  }

  static Object? _clone(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>((k, v) => MapEntry(k as String, _clone(v)));
    }
    if (value is List) {
      return value.map(_clone).toList();
    }
    return value;
  }
}
