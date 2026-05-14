import 'dart:io';
import 'package:flutter/material.dart';

import 'image_overlay.dart';
import 'resize_handle.dart';

class EditableImageBox extends StatelessWidget {
  final ImageOverlay image;
  final Size displaySize;

  final VoidCallback onTap;

  final void Function(Offset delta) onMove;

  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;

  final VoidCallback onResizeStart;
  final void Function(Offset delta, ResizeHandle handle) onResize;

  final VoidCallback onRotateStart;
  final void Function(Offset globalPosition) onRotate;

  const EditableImageBox({
    super.key,
    required this.image,
    required this.displaySize,
    required this.onTap,
    required this.onMove,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onResizeStart,
    required this.onResize,
    required this.onRotateStart,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      // Scale recognizer xử lý cả move 1 ngón và pinch 2 ngón
      onScaleStart: onScaleStart,
      onScaleUpdate: (details) {
        if (details.pointerCount == 1) {
          onMove(details.focalPointDelta);
        } else {
          onScaleUpdate(details);
        }
      },

      child: Transform.rotate(
        angle: image.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.file(
              File(image.imagePath),
              width: displaySize.width,
              height: displaySize.height,
              fit: BoxFit.fill,
            ),

            if (image.selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                  ),
                ),
              ),

            if (image.selected) ...[
              Positioned(
                top: -42,
                left: displaySize.width / 2 - 1,
                child: Container(width: 2, height: 32, color: Colors.blue),
              ),

              Positioned(
                top: -64,
                left: displaySize.width / 2 - 12,
                child: GestureDetector(
                  onPanStart: (_) => onRotateStart(),
                  onPanUpdate: (d) => onRotate(d.globalPosition),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),

              _handle(ResizeHandle.topLeft, Alignment.topLeft),
              _handle(ResizeHandle.topRight, Alignment.topRight),
              _handle(ResizeHandle.bottomLeft, Alignment.bottomLeft),
              _handle(ResizeHandle.bottomRight, Alignment.bottomRight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handle(ResizeHandle handle, Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onPanStart: (_) => onResizeStart(),
          onPanUpdate: (d) => onResize(d.delta, handle),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
