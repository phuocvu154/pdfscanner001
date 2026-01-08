import 'package:flutter/material.dart';
import 'text_overlay.dart';
import 'image_overlay.dart';

class EditPageViewModel extends ChangeNotifier {
  final String imagePath;

  final List<TextOverlay> _texts;
  final List<List<TextOverlay>> _undoStack = [];
  final List<List<TextOverlay>> _redoStack = [];

  final List<ImageOverlay> _images;
  List<ImageOverlay> get images => List.unmodifiable(_images);
  List<TextOverlay> get texts => List.unmodifiable(_texts);

  EditPageViewModel({
    required this.imagePath,
    required List<TextOverlay> initialTexts,
    required List<ImageOverlay> initialImages,
  }) : _texts = List.of(initialTexts),
       _images = List.of(initialImages);

  // ================= UNDO =================
  void _pushUndo() {
    _undoStack.add(List.of(_texts));
    _redoStack.clear();
  }

  double _startScale = 1;
  double _startRotation = 0;

  double _startImageScale = 1.0;
  double _startImageRotation = 0.0;

  GestureScaleStartCallback onImageScaleStart(int index) {
    return (details) {
      _startImageScale = _images[index].scale;
      _startImageRotation = _images[index].rotation;
    };
  }

  GestureScaleUpdateCallback onImageScaleUpdate(int index) {
    return (details) {
      final img = _images[index];

      _images[index] = img.copyWith(
        scale: (_startImageScale * details.scale).clamp(0.05, 3.0),
        rotation: _startImageRotation + details.rotation,
      );

      notifyListeners();
    };
  }

  void deleteImage(int index) {
    _pushUndo();
    _images.removeAt(index);
    notifyListeners();
  }

  // ================= ADD IMAGE =================
  void addImage(String path) {
    _pushUndo();

    _images.add(
      ImageOverlay(imagePath: path, relativePosition: const Offset(0.5, 0.5)),
    );

    notifyListeners();
  }

  void selectImage(int index) {
    for (int i = 0; i < _images.length; i++) {
      _images[i] = _images[i].copyWith(selected: i == index);
    }
    notifyListeners();
  }

  void moveImage(int index, Offset delta, Size renderSize) {
    _pushUndo();

    final img = _images[index];

    final dx = delta.dx / renderSize.width;
    final dy = delta.dy / renderSize.height;

    final newPos = Offset(
      (img.relativePosition.dx + dx).clamp(0.0, 1.0),
      (img.relativePosition.dy + dy).clamp(0.0, 1.0),
    );

    _images[index] = img.copyWith(relativePosition: newPos);
    notifyListeners();
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
  double _startFontRotation = 0;

  GestureScaleStartCallback onScaleStart(int index) {
    return (_) {
      _pushUndo();
      _startFontScale = _texts[index].fontScale;
      _startFontRotation = _texts[index].rotation;
    };
  }

  GestureScaleUpdateCallback onScaleUpdate(int index) {
    return (details) {
      final t = _texts[index];

      _texts[index] = t.copyWith(
        fontScale: (_startFontScale * details.scale).clamp(0.01, 0.3),
        rotation: _startFontRotation + details.rotation,
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
