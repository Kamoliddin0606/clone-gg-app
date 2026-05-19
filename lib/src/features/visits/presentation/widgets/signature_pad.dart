import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Minimal signature canvas — strokes are stored as a list of polylines.
///
/// We intentionally avoid `signature_pad`-style third-party packages
/// because:
///   * the rendering surface is small (one or two screens) and
///   * we already control the export path (PNG → base64 → task payload),
///     so a 3rd-party dependency would mostly duplicate `CustomPainter`.
///
/// The widget exposes:
///   * [SignaturePadController] — clear / undo / export PNG bytes.
///   * `onChanged` — fires every time the user lifts their finger so a
///     parent renderer can refresh the "completed" gate.
///
/// PNG export uses `ui.PictureRecorder` + `Image.toByteData` so the
/// output is deterministic regardless of the device pixel ratio.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.controller,
    this.strokeWidth = 2.5,
    this.strokeColor = Colors.black,
    this.backgroundColor = const Color(0xFFF3F3F3),
    this.height = 240,
    this.onChanged,
  });

  final SignaturePadController controller;
  final double strokeWidth;
  final Color strokeColor;
  final Color backgroundColor;
  final double height;
  final VoidCallback? onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  void _addStroke() => _strokes.add(<Offset>[]);

  void _addPoint(Offset point) {
    if (_strokes.isEmpty) _addStroke();
    _strokes.last.add(point);
  }

  void _commitStroke() {
    widget.onChanged?.call();
  }

  bool get _hasInk =>
      _strokes.any((stroke) => stroke.isNotEmpty);

  void _clear() {
    setState(_strokes.clear);
    widget.onChanged?.call();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onChanged?.call();
  }

  Future<Uint8List?> _exportPng(Size size) async {
    if (!_hasInk) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
    final bg = Paint()..color = widget.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    _SignaturePainter(
      strokes: _strokes,
      strokeColor: widget.strokeColor,
      strokeWidth: widget.strokeWidth,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              Size(constraints.maxWidth, widget.height);
          // Stash the size on the controller so external `export` calls
          // know the canvas dimensions; the controller would otherwise
          // have to walk the element tree.
          widget.controller._size = size;
          return GestureDetector(
            onPanStart: (d) {
              setState(() {
                _addStroke();
                _addPoint(d.localPosition);
              });
            },
            onPanUpdate: (d) {
              setState(() => _addPoint(d.localPosition));
            },
            onPanEnd: (_) => _commitStroke(),
            child: ClipRect(
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                  background: widget.backgroundColor,
                ),
                size: size,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Talks to the [SignaturePad] state from outside. Hand one to the
/// renderer that owns the form (e.g. `SignatureField`) so it can ask the
/// pad to clear / undo / export bytes when the user taps a button.
class SignaturePadController {
  _SignaturePadState? _state;
  Size? _size;

  void _attach(_SignaturePadState state) => _state = state;
  void _detach(_SignaturePadState state) {
    if (_state == state) _state = null;
  }

  bool get isEmpty => _state == null ? true : !_state!._hasInk;

  void clear() => _state?._clear();
  void undo() => _state?._undo();

  Future<Uint8List?> exportPng() async {
    final state = _state;
    final size = _size;
    if (state == null || size == null) return null;
    return state._exportPng(size);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
    this.background,
  });

  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = background!,
      );
    }
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          canvas.drawPoints(ui.PointMode.points, stroke, paint);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) {
    // The strokes list is mutated in place; a length check covers
    // append/clear/undo, which is the only thing that changes between
    // `setState` calls. Stroke-content edits would need deep compare,
    // but the widget never mutates a stroke after committing it.
    return old.strokes.length != strokes.length ||
        (strokes.isNotEmpty &&
            strokes.last.length != old.strokes.last.length);
  }
}
