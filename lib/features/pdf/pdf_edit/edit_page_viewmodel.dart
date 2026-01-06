import 'package:flutter/material.dart';
import 'edit_models.dart';

class EditPageViewModel extends ChangeNotifier {
  final String imagePath;

  final List<TextOverlay> _texts;
  final List<List<TextOverlay>> _undoStack = [];
  final List<List<TextOverlay>> _redoStack = [];

  EditPageViewModel({
    required this.imagePath,
    required List<TextOverlay> initialTexts,
  }) : _texts = List.of(initialTexts);

  List<TextOverlay> get texts => List.unmodifiable(_texts);

  // ================= UNDO =================
  void _pushUndo() {
    _undoStack.add(List.of(_texts));
    _redoStack.clear();
  }

  // ================= ADD =================
  void addText(
    String text,
    Offset relativePosition,
    double fontScale, {
    Color color = Colors.black,
    String fontFamily = 'Roboto',
  }) {
    _pushUndo();
    _texts.add(
      TextOverlay(
        text: text,
        relativePosition: relativePosition,
        fontScale: fontScale,
        color: color,
        fontFamily: fontFamily,
      ),
    );
    notifyListeners();
  }

  // ================= MOVE =================
  void moveText(int index, Offset delta, Size renderSize) {
    _pushUndo();

    final t = _texts[index];

    final dx = delta.dx / renderSize.width;
    final dy = delta.dy / renderSize.height;

    _texts[index] = t.copyWith(
      relativePosition: Offset(
        (t.relativePosition.dx + dx).clamp(0.0, 1.0),
        (t.relativePosition.dy + dy).clamp(0.0, 1.0),
      ),
    );

    notifyListeners();
  }

  // ================= SCALE + ROTATE =================
  double _startFontScale = 1;
  double _startRotation = 0;

  GestureScaleStartCallback onScaleStart(int index) {
    return (_) {
      _pushUndo();
      _startFontScale = _texts[index].fontScale;
      _startRotation = _texts[index].rotation;
    };
  }

  GestureScaleUpdateCallback onScaleUpdate(int index) {
    return (details) {
      final t = _texts[index];

      _texts[index] = t.copyWith(
        fontScale: (_startFontScale * details.scale).clamp(0.01, 0.3),
        rotation: _startRotation + details.rotation,
      );

      notifyListeners();
    };
  }

  // ================= UPDATE (EDIT TEXT / COLOR / FONT) =================
  void updateText(
    int index, {
    String? text,
    Color? color,
    double? fontScale,
    String? fontFamily,
    double? rotation,
  }) {
    _pushUndo();

    final old = _texts[index];
    _texts[index] = old.copyWith(
      text: text,
      color: color,
      fontScale: fontScale,
      fontFamily: fontFamily,
      rotation: rotation,
    );

    notifyListeners();
  }

  // ================= DELETE =================
  void deleteText(int index) {
    _pushUndo();
    _texts.removeAt(index);
    notifyListeners();
  }

  // ================= UNDO / REDO =================
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.of(_texts));
    _texts
      ..clear()
      ..addAll(_undoStack.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.of(_texts));
    _texts
      ..clear()
      ..addAll(_redoStack.removeLast());
    notifyListeners();
  }
}
