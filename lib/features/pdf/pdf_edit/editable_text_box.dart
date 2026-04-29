import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'text_overlay.dart';

class EditableTextBox extends StatelessWidget {
  final TextOverlay text;
  final Size renderSize;

  final VoidCallback onTap;
  final Function(Offset delta) onMove;
  final Function(double scale) onResize;
  final Function(double angle) onRotate;

  const EditableTextBox({
    super.key,
    required this.text,
    required this.renderSize,
    required this.onTap,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = text.fontScale * renderSize.width;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (d) => onMove(d.delta), // ✅ MOVE 1 NGÓN
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateZ(text.rotation),
            child: Text(
              text.text,
              style: TextStyle(
                fontSize: fontSize,
                color: text.color,
                fontFamily: text.fontFamily,
              ),
            ),
          ),

          if (text.selected) ...[_resizeHandle(), _rotateHandle()],
        ],
      ),
    );
  }

  Widget _resizeHandle() {
    return Positioned(
      right: -16,
      bottom: -16,
      child: GestureDetector(
        onPanUpdate: (d) {
          final scale = 1 + d.delta.dx / renderSize.width;
          onResize(scale);
        },
        child: _dot(),
      ),
    );
  }

  Widget _rotateHandle() {
    return Positioned(
      top: -32,
      left: 0,
      right: 0,
      child: GestureDetector(
        onPanUpdate: (d) {
          onRotate(d.delta.dx * math.pi / 180);
        },
        child: Column(
          children: [
            Container(width: 2, height: 16, color: Colors.blue),
            _dot(),
          ],
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}
