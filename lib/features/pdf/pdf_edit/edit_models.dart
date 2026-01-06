import 'package:flutter/material.dart';

class TextOverlay {
  final String text;
  final Offset relativePosition;
  final double fontSize;
  final Color color;

  // 🔴 THÊM FIELD NÀY
  

  TextOverlay({
    required this.text,
    required this.relativePosition,
    required this.fontSize,
    required this.color,
    
  });

  TextOverlay copyWith({
    String? text,
    Offset? relativePosition,
    double? fontSize,
    Color? color,
    double? fontScale,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      relativePosition: relativePosition ?? this.relativePosition,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      
    );
  }
}
