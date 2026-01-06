import 'package:flutter/material.dart';

class TextOverlay {
  final String text;

  /// 0.0 → 1.0 theo ảnh gốc
  final Offset relativePosition;

  /// scale theo chiều rộng ảnh (vd: 0.04 = 4%)
  final double fontScale;

  final Color color;
  final String fontFamily;

  const TextOverlay({
    required this.text,
    required this.relativePosition,
    required this.fontScale,
    required this.color,
    required this.fontFamily,
  });

  TextOverlay copyWith({
    String? text,
    Offset? relativePosition,
    double? fontScale,
    Color? color,
    String? fontFamily,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      relativePosition: relativePosition ?? this.relativePosition,
      fontScale: fontScale ?? this.fontScale,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
