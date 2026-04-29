import 'dart:ui';

class ImageOverlay {
  final String imagePath;
  final Offset relativePosition;
  final double scale;
  final double rotation;
  final bool selected;
  final Size? naturalSize; // ← thêm

  const ImageOverlay({
    required this.imagePath,
    required this.relativePosition,
    this.scale = 0.25,
    this.rotation = 0.0,
    this.selected = false,
    this.naturalSize, // ← thêm
  });

  ImageOverlay copyWith({
    String? imagePath,
    Offset? relativePosition,
    double? scale,
    double? rotation,
    bool? selected,
    Size? naturalSize, // ← thêm
  }) {
    return ImageOverlay(
      imagePath: imagePath ?? this.imagePath,
      relativePosition: relativePosition ?? this.relativePosition,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      selected: selected ?? this.selected,
      naturalSize: naturalSize ?? this.naturalSize, // ← thêm
    );
  }
}
