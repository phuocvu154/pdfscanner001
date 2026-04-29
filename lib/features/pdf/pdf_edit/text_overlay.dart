import 'dart:ui';

class TextOverlay {
  final String text;
  final Offset relativePosition; // 0..1
  final double fontScale; // ✅ GIỮ NGUYÊN
  final Color color;
  final String fontFamily;
  final double rotation;
  final bool selected;

  const TextOverlay({
    required this.text,
    required this.relativePosition,
    required this.fontScale,
    required this.color,
    required this.fontFamily,
    this.rotation = 0,
    this.selected = false,
  });

  TextOverlay copyWith({
    String? text,
    Offset? relativePosition,
    double? fontScale,
    Color? color,
    String? fontFamily,
    double? rotation,
    bool? selected,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      relativePosition: relativePosition ?? this.relativePosition,
      fontScale: fontScale ?? this.fontScale,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      rotation: rotation ?? this.rotation,
      selected: selected ?? this.selected,
    );
  }
}
