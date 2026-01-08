import 'dart:ui';

class ImageOverlay {
  final String imagePath;
  final Offset relativePosition; // 0..1
  final double scale;            // pinch zoom
  final double rotation;         // radians
  final bool selected;

  const ImageOverlay({
    required this.imagePath,
    required this.relativePosition,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.selected = false,
  });

  ImageOverlay copyWith({
    String? imagePath,
    Offset? relativePosition,
    double? scale,
    double? rotation,
    bool? selected,
  }) {
    return ImageOverlay(
      imagePath: imagePath ?? this.imagePath,
      relativePosition: relativePosition ?? this.relativePosition,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      selected: selected ?? this.selected,
    );
  }
}
