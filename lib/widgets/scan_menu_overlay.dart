import 'package:flutter/material.dart';
import 'package:pdfscanner001/features/pdf/pdf_viewmodel.dart';
import 'package:pdfscanner001/features/scan/scan_view.dart';
import 'package:pdfscanner001/features/scan/scan_viewmodel.dart';
import 'package:provider/provider.dart';

import '../features/home/viewmodel/home_viewmodel.dart';

class ScanMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const ScanMenuOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // 🔹 FAB centerDocked
    final fabRadius = 28.0;
    final fabCenterX = media.size.width / 2;
    final fabTopY =
        media.size.height - media.padding.bottom - 56 - fabRadius * 2;

    return Material(
      color: Colors.black.withOpacity(0.3),
      child: GestureDetector(
        onTap: onClose,
        child: Stack(
          children: [
            Positioned(
              bottom: media.size.height - fabTopY,
              left: fabCenterX - 140, // width popup / 2
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BubbleMenu(
                      onSelect: (value) {
                        onClose();
                        debugPrint('Selected: $value');
                      },
                    ),
                    CustomPaint(
                      size: const Size(30, 20),
                      painter: _TrianglePainter(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleMenu extends StatelessWidget {
  final Function(String) onSelect;

  const _BubbleMenu({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you like to scan?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _menuButton('Camera', () {
            onSelect('camera');
            context.read<HomeViewModel>().openScanner(context);
          }),

          const SizedBox(height: 12),
          _menuButton('From Library', () => onSelect('library')),
          const SizedBox(height: 12),
          _menuButton('Import File', () => onSelect('import')),
        ],
      ),
    );
  }

  Widget _menuButton(String title, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 44,
        width: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
