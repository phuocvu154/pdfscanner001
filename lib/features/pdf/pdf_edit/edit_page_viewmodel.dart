import 'package:flutter/material.dart';
import '../../documents/document_item.dart';

class EditableText {
  String text;
  Offset position;
  double fontSize;
  Color color;

  EditableText({
    required this.text,
    required this.position,
    this.fontSize = 18,
    this.color = Colors.black,
  });

  EditableText copy() => EditableText(
    text: text,
    position: position,
    fontSize: fontSize,
    color: color,
  );
}

class EditPageViewModel extends ChangeNotifier {
  final DocumentItem document;

  EditPageViewModel(this.document);

  final List<EditableText> texts = [];

  final List<List<EditableText>> _undoStack = [];
  final List<List<EditableText>> _redoStack = [];

  int currentPage = 0;

  // ===== PAGE =====
  void changePage(int index) {
    currentPage = index;
    notifyListeners();
  }

  // ===== UNDO / REDO =====
  void _saveState() {
    _undoStack.add(texts.map((e) => e.copy()).toList());
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(texts.map((e) => e.copy()).toList());
    texts
      ..clear()
      ..addAll(_undoStack.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(texts.map((e) => e.copy()).toList());
    texts
      ..clear()
      ..addAll(_redoStack.removeLast());
    notifyListeners();
  }

  // ===== TEXT =====
  void addText(String value, Size canvasSize) {
    _saveState();
    texts.add(
      EditableText(
        text: value,
        position: Offset(canvasSize.width / 2 - 40, canvasSize.height / 2 - 20),
      ),
    );
    notifyListeners();
  }

  void updateText(int index, EditableText updated) {
    _saveState();
    texts[index] = updated;
    notifyListeners();
  }

  void moveText(int index, Offset delta) {
    texts[index].position += delta;
    notifyListeners();
  }

  void deleteText(int index) {
    _saveState();
    texts.removeAt(index);
    notifyListeners();
  }
}
