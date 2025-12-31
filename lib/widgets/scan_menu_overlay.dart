import 'package:flutter/material.dart';
import 'package:pdfscanner001/features/scan_result_preview/scan_service.dart';

import '../features/documents/document_item.dart';

import '../features/scan_result_preview/scan_result_screen.dart';

class ScanMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  // 🔴 THÊM FIELD NÀY
  final void Function(DocumentItem? doc) onScanCompleted;

  const ScanMenuOverlay({
    super.key,
    required this.onClose,
    required this.onScanCompleted, // 🔴 BẮT BUỘC
  });

  // ===== CAMERA FLOW =====
  Future<void> _onCameraPressed(BuildContext context) async {
    // ❌ KHÔNG onClose ở đây
    // onClose();
    final scanner = DocumentScannerService();
    final images = await scanner.scan();
    scanner.dispose();
    // 👉 ĐÓNG OVERLAY SAU KHI SCAN XONG
    onClose();
    if (images.isEmpty) {
      debugPrint('🚫 User cancelled scan');
      return;
    }
    final DocumentItem? doc = await Navigator.push<DocumentItem>(
      context,
      MaterialPageRoute(builder: (_) => ScanResultScreen(imageUris: images)),
    );

    if (doc != null) {
      onScanCompleted(doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // FAB position
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
              left: fabCenterX - 140,
              child: GestureDetector(
                onTap: () {}, // chặn tap xuyên
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BubbleMenu(
                      onCameraTap: () => _onCameraPressed(context),
                      onLibraryTap: () {
                        // TODO: chọn ảnh từ gallery
                      },
                      onImportTap: () {
                        // TODO: import PDF
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

// =================== MENU ===================

class _BubbleMenu extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onLibraryTap;
  final VoidCallback onImportTap;

  const _BubbleMenu({
    required this.onCameraTap,
    required this.onLibraryTap,
    required this.onImportTap,
  });

  @override
  Widget build(BuildContext context) {
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

          _menuButton('Camera', onCameraTap),
          const SizedBox(height: 12),

          _menuButton('From Library', onLibraryTap),
          const SizedBox(height: 12),

          _menuButton('Import File', onImportTap),
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
        width: 140,
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

// =================== TRIANGLE ===================

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
