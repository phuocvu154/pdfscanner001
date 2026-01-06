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

  void _pushUndo() {
    _undoStack.add(List.of(_texts));
    _redoStack.clear();
  }

  // ✅ ADD TEXT Ở GIỮA ẢNH
  void addText(String text, Offset offset) {
    _pushUndo();

    _texts.add(
      TextOverlay(
        text: text,
        relativePosition: const Offset(0.5, 0.5),
        fontScale: 0.04, // ~ 4% width ảnh
        color: Colors.white,
        fontFamily: 'Roboto',
      ),
    );

    notifyListeners();
  }

  void moveTextRelative(int index, Offset delta) {
    _pushUndo();

    final t = _texts[index];
    _texts[index] = t.copyWith(
      relativePosition: Offset(
        (t.relativePosition.dx + delta.dx).clamp(0.0, 1.0),
        (t.relativePosition.dy + delta.dy).clamp(0.0, 1.0),
      ),
    );

    notifyListeners();
  }

  void updateText(int index, TextOverlay updated) {
    _pushUndo();
    _texts[index] = updated;
    notifyListeners();
  }

  void deleteText(int index) {
    _pushUndo();
    _texts.removeAt(index);
    notifyListeners();
  }

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
