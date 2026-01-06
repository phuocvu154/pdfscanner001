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

  // ✅ PUBLIC READ-ONLY
  List<TextOverlay> get texts => List.unmodifiable(_texts);

  // ===== ADD =====
 // edit_page_viewmodel.dart

void addText(String text, Offset relativePosition) {
  _pushUndo();

  _texts.add(
    TextOverlay(
      text: text,
      relativePosition: relativePosition, // 0..1
      fontSize: 18,
      color: Colors.black,
    ),
  );

  notifyListeners();
}



  // ===== MOVE =====
  void moveTextRelative(int index, Offset delta) {
  _pushUndo();

  final t = _texts[index];
  final newPos = Offset(
    (t.relativePosition.dx + delta.dx).clamp(0.0, 1.0),
    (t.relativePosition.dy + delta.dy).clamp(0.0, 1.0),
  );

  _texts[index] = t.copyWith(relativePosition: newPos);
  notifyListeners();
}


  // ===== UPDATE =====
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

  // ===== UNDO / REDO =====
  void _pushUndo() {
    _undoStack.add(List.of(_texts));
    _redoStack.clear();
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
