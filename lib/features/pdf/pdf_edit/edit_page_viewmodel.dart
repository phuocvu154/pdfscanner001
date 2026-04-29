import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'text_overlay.dart';
import 'image_overlay.dart';

class EditPageViewModel extends ChangeNotifier {
  final String imagePath;

  final List<TextOverlay> _texts;
  final List<ImageOverlay> _images;

  List<TextOverlay> get texts => List.unmodifiable(_texts);
  List<ImageOverlay> get images => List.unmodifiable(_images);

  final List<_EditSnapshot> _undoStack = [];
  final List<_EditSnapshot> _redoStack = [];

  EditPageViewModel({
    required this.imagePath,
    required List<TextOverlay> initialTexts,
    required List<ImageOverlay> initialImages,
  }) : _texts = initialTexts.map((e) => e.copyWith()).toList(),
       _images = initialImages.map((e) => e.copyWith()).toList();

  double _startFontScale = 1.0;
  double _startFontRotation = 0.0;

  double _startImageScale = 1.0;
  double _startImageRotation = 0.0;

  Size _renderSize = Size.zero;
  Size get renderSize => _renderSize;

  void setRenderSize(Size size) {
    if (_renderSize == size) return;
    _renderSize = size;
  }

  void _pushUndo() {
    _undoStack.add(
      _EditSnapshot(
        texts: _texts.map((e) => e.copyWith()).toList(),
        images: _images.map((e) => e.copyWith()).toList(),
      ),
    );
    _redoStack.clear();
  }

  void _restore(_EditSnapshot snapshot) {
    _texts
      ..clear()
      ..addAll(snapshot.texts.map((e) => e.copyWith()));
    _images
      ..clear()
      ..addAll(snapshot.images.map((e) => e.copyWith()));
  }

  Offset _clampOffset(Offset value) {
    return Offset(value.dx.clamp(0.0, 1.0), value.dy.clamp(0.0, 1.0));
  }

  void clearSelections() {
    for (int i = 0; i < _texts.length; i++) {
      _texts[i] = _texts[i].copyWith(selected: false);
    }
    for (int i = 0; i < _images.length; i++) {
      _images[i] = _images[i].copyWith(selected: false);
    }
    notifyListeners();
  }

  void selectText(int index) {
    for (int i = 0; i < _texts.length; i++) {
      _texts[i] = _texts[i].copyWith(selected: i == index);
    }
    for (int i = 0; i < _images.length; i++) {
      _images[i] = _images[i].copyWith(selected: false);
    }
    notifyListeners();
  }

  void selectImage(int index) {
    for (int i = 0; i < _images.length; i++) {
      _images[i] = _images[i].copyWith(selected: i == index);
    }
    for (int i = 0; i < _texts.length; i++) {
      _texts[i] = _texts[i].copyWith(selected: false);
    }
    notifyListeners();
  }

  void addText(
    String text,
    Offset relativePosition,
    double fontScale, {
    Color color = Colors.black,
    String fontFamily = 'Roboto',
  }) {
    _pushUndo();

    for (int i = 0; i < _images.length; i++) {
      _images[i] = _images[i].copyWith(selected: false);
    }
    for (int i = 0; i < _texts.length; i++) {
      _texts[i] = _texts[i].copyWith(selected: false);
    }

    _texts.add(
      TextOverlay(
        text: text,
        relativePosition: _clampOffset(relativePosition),
        fontScale: fontScale.clamp(0.01, 1.0),
        color: color,
        fontFamily: fontFamily,
        rotation: 0,
        selected: true,
      ),
    );
    notifyListeners();
  }

  void addImage(String path) {
    _pushUndo();
    // deselect tất cả...

    _images.add(
      ImageOverlay(
        imagePath: path,
        relativePosition: const Offset(0.5, 0.5),
        scale: 0.25,
        selected: true,
      ),
    );
    notifyListeners();

    // Load natural size async
    _loadImageNaturalSize(path, _images.length - 1);
  }

  Future<void> _loadImageNaturalSize(String path, int index) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();

      if (index < _images.length && _images[index].imagePath == path) {
        _images[index] = _images[index].copyWith(naturalSize: Size(w, h));
        notifyListeners();
      }
    } catch (_) {}
  }

  void deleteText(int index) {
    if (index < 0 || index >= _texts.length) return;
    _pushUndo();
    _texts.removeAt(index);
    notifyListeners();
  }

  void deleteImage(int index) {
    if (index < 0 || index >= _images.length) return;
    _pushUndo();
    _images.removeAt(index);
    notifyListeners();
  }

  void updateText(
    int index, {
    String? text,
    Color? color,
    double? fontScale,
    String? fontFamily,
    double? rotation,
  }) {
    if (index < 0 || index >= _texts.length) return;
    _pushUndo();

    final old = _texts[index];
    _texts[index] = old.copyWith(
      text: text,
      color: color,
      fontScale: fontScale?.clamp(0.01, 1.0),
      fontFamily: fontFamily,
      rotation: rotation,
    );
    notifyListeners();
  }

  void moveText(int index, Offset delta, Size renderSize) {
    if (index < 0 || index >= _texts.length) return;
    if (renderSize.width <= 0 || renderSize.height <= 0) return;

    final t = _texts[index];
    final dx = delta.dx / renderSize.width;
    final dy = delta.dy / renderSize.height;

    _texts[index] = t.copyWith(
      relativePosition: _clampOffset(
        Offset(t.relativePosition.dx + dx, t.relativePosition.dy + dy),
      ),
    );
    notifyListeners();
  }

  void moveImage(int index, Offset delta, Size renderSize) {
    if (index < 0 || index >= _images.length) return;
    if (renderSize.width <= 0 || renderSize.height <= 0) return;

    final img = _images[index];
    final dx = delta.dx / renderSize.width;
    final dy = delta.dy / renderSize.height;

    _images[index] = img.copyWith(
      relativePosition: _clampOffset(
        Offset(img.relativePosition.dx + dx, img.relativePosition.dy + dy),
      ),
    );
    notifyListeners();
  }

  GestureScaleStartCallback onScaleStart(int index) {
    return (_) {
      if (index < 0 || index >= _texts.length) return;
      _pushUndo();
      selectText(index);
      _startFontScale = _texts[index].fontScale;
      _startFontRotation = _texts[index].rotation;
    };
  }

  GestureScaleUpdateCallback onScaleUpdate(int index) {
    return (details) {
      if (index < 0 || index >= _texts.length) return;
      final t = _texts[index];

      _texts[index] = t.copyWith(
        fontScale: (_startFontScale * details.scale).clamp(0.01, 1.0),
        rotation: _startFontRotation + details.rotation,
      );
      notifyListeners();
    };
  }

  GestureScaleStartCallback onImageScaleStart(int index) {
    return (_) {
      if (index < 0 || index >= _images.length) return;
      _pushUndo();
      selectImage(index);
      _startImageScale = _images[index].scale;
      _startImageRotation = _images[index].rotation;
    };
  }

  GestureScaleUpdateCallback onImageScaleUpdate(int index, Size renderSize) {
    return (details) {
      if (index < 0 || index >= _images.length) return;

      final img = _images[index];

      if (details.pointerCount == 1) {
        final dx = details.focalPointDelta.dx / renderSize.width;
        final dy = details.focalPointDelta.dy / renderSize.height;

        _images[index] = img.copyWith(
          relativePosition: _clampOffset(
            Offset(img.relativePosition.dx + dx, img.relativePosition.dy + dy),
          ),
        );
      } else {
        _images[index] = img.copyWith(
          scale: (_startImageScale * details.scale).clamp(0.05, 1.5),
          rotation: _startImageRotation + details.rotation,
        );
      }

      notifyListeners();
    };
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(
      _EditSnapshot(
        texts: _texts.map((e) => e.copyWith()).toList(),
        images: _images.map((e) => e.copyWith()).toList(),
      ),
    );

    final snapshot = _undoStack.removeLast();
    _restore(snapshot);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(
      _EditSnapshot(
        texts: _texts.map((e) => e.copyWith()).toList(),
        images: _images.map((e) => e.copyWith()).toList(),
      ),
    );

    final snapshot = _redoStack.removeLast();
    _restore(snapshot);
    notifyListeners();
  }
}

class _EditSnapshot {
  final List<TextOverlay> texts;
  final List<ImageOverlay> images;

  const _EditSnapshot({required this.texts, required this.images});
}
