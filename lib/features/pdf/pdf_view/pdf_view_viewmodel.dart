import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../../scan_result_preview/scan_service.dart';

import '../pdf_edit/image_overlay.dart';
import '../pdf_edit/text_overlay.dart';
import '../pdf_edit_service.dart';

class PdfViewViewModel extends ChangeNotifier {
  final DocumentItem document;

  PdfViewViewModel(this.document) {
    _loadPages();
  }

  // 🔴 BỎ _pages list để tiết kiệm RAM
  final List<String> _pageImagePaths = [];

  final Map<int, List<TextOverlay>> _pageTextOverlays = {};
  final Map<int, List<ImageOverlay>> _pageImageOverlays = {};

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isProcessing = false;

  // ===== GETTERS =====
  List<String> get pageImagePaths => _pageImagePaths;
  int get total => _pageImagePaths.length;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isAddingPage => _isProcessing;

  List<TextOverlay> textOverlaysOfPage(int page) =>
      _pageTextOverlays[page] ?? [];
  List<ImageOverlay> imageOverlaysOfPage(int page) =>
      _pageImageOverlays[page] ?? [];

  // ===== LOAD PAGES =====
  Future<void> _loadPages() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final oldPath in _pageImagePaths) {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      }

      _pageImagePaths.clear();

      final tempDir = await getTemporaryDirectory();
      final bytes = await File(document.path).readAsBytes();

      final raster = Printing.raster(bytes, dpi: 72);

      int pageIndex = 0;
      final stamp = DateTime.now().millisecondsSinceEpoch;

      await for (final page in raster) {
        final pngBytes = await page.toPng();

        final imagePath =
            '${tempDir.path}/pdf_page_${document.id}_${stamp}_$pageIndex.png';

        await File(imagePath).writeAsBytes(pngBytes, flush: true);
        _pageImagePaths.add(imagePath);

        pageIndex++;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== PAGE NAVIGATION =====
  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // ===== DELETE PAGE =====
  void deleteCurrent() {
    if (_pageImagePaths.length <= 1) return;

    _pageImagePaths.removeAt(_currentIndex);
    _pageTextOverlays.remove(_currentIndex);
    _pageImageOverlays.remove(_currentIndex);

    _shiftOverlayIndices(_currentIndex);

    if (_currentIndex >= _pageImagePaths.length) {
      _currentIndex = _pageImagePaths.length - 1;
    }
    notifyListeners();
  }

  void _shiftOverlayIndices(int deletedIndex) {
    final newTextOverlays = <int, List<TextOverlay>>{};
    final newImageOverlays = <int, List<ImageOverlay>>{};

    _pageTextOverlays.forEach((key, value) {
      if (key > deletedIndex) {
        newTextOverlays[key - 1] = value;
      } else if (key < deletedIndex) {
        newTextOverlays[key] = value;
      }
    });

    _pageImageOverlays.forEach((key, value) {
      if (key > deletedIndex) {
        newImageOverlays[key - 1] = value;
      } else if (key < deletedIndex) {
        newImageOverlays[key] = value;
      }
    });

    _pageTextOverlays
      ..clear()
      ..addAll(newTextOverlays);
    _pageImageOverlays
      ..clear()
      ..addAll(newImageOverlays);
  }

  // ===== ADD PAGE =====
  Future<void> addPage() async {
    if (_isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final scanner = DocumentScannerService();
      final images = await scanner.scan();
      scanner.dispose();

      if (images.isEmpty) return;

      final editor = PdfEditService();
      await editor.appendImagesToPdf(
        pdfPath: document.path,
        imagePaths: images,
      );

      await _loadPages();
      _currentIndex = _pageImagePaths.length - 1;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ===== SET OVERLAYS =====
  void setPageTextOverlays(int pageIndex, List<TextOverlay> overlays) {
    _pageTextOverlays[pageIndex] = List.of(overlays);
    notifyListeners();
  }

  void setPageImageOverlays(int pageIndex, List<ImageOverlay> overlays) {
    _pageImageOverlays[pageIndex] = List.of(overlays);
    notifyListeners();
  }

  // ===== SHARE =====
  Future<void> share() async {
    await Printing.sharePdf(
      bytes: await File(document.path).readAsBytes(),
      filename: document.name,
    );
  }

  // ===== SAVE WITH EDITS =====
  Future<void> saveWithEdits() async {
    // ✅ Bỏ early return — luôn save dù không có overlay
    _isProcessing = true;
    notifyListeners();

    try {
      const pageFormat = PdfPageFormat.a4;
      final pdf = pw.Document();

      for (int pageIndex = 0; pageIndex < _pageImagePaths.length; pageIndex++) {
        final bytes = await File(_pageImagePaths[pageIndex]).readAsBytes();

        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        final imgW = uiImage.width.toDouble();
        final imgH = uiImage.height.toDouble();

        // ✅ Dùng imgW/imgH làm canvas, không dùng A4 làm gốc tính offset
        // để relativePosition khớp với EditPageScreen
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));

        // ===== DRAW BASE IMAGE =====
        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(0, 0, imgW, imgH),
          Rect.fromLTWH(0, 0, imgW, imgH), // ✅ full, không offset
          Paint(),
        );

        // ===== DRAW TEXT OVERLAYS =====
        final texts = _pageTextOverlays[pageIndex] ?? [];
        for (final t in texts) {
          final fontSize = t.fontScale * imgW; // ✅ relative theo imgW

          canvas.save();
          canvas.translate(
            t.relativePosition.dx * imgW, // ✅ không cộng offsetX/offsetY
            t.relativePosition.dy * imgH,
          );
          canvas.rotate(t.rotation);

          final textPainter = TextPainter(
            text: TextSpan(
              text: t.text,
              style: TextStyle(
                fontSize: fontSize,
                color: t.color,
                fontFamily: t.fontFamily,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
        }

        // ===== DRAW IMAGE OVERLAYS (signature) =====
        final images = _pageImageOverlays[pageIndex] ?? [];
        for (final img in images) {
          final centerX = img.relativePosition.dx * imgW; // ✅ không cộng offset
          final centerY = img.relativePosition.dy * imgH;

          final overlayBytes = await File(img.imagePath).readAsBytes();
          final overlayCodec = await ui.instantiateImageCodec(overlayBytes);
          final overlayFrame = await overlayCodec.getNextFrame();
          final overlayImage = overlayFrame.image;

          final overlayW = overlayImage.width.toDouble();
          final scalePx = img.scale * imgW; // ✅ scale theo imgW

          canvas.save();
          canvas.translate(centerX, centerY);
          canvas.rotate(img.rotation);
          canvas.scale(scalePx / overlayW, scalePx / overlayW);
          canvas.drawImage(
            overlayImage,
            Offset(-overlayW / 2, -overlayImage.height / 2),
            Paint(),
          );
          canvas.restore();
        }

        final picture = recorder.endRecording();
        // ✅ Canvas size = image size, không dùng A4
        final composed = await picture.toImage(imgW.toInt(), imgH.toInt());

        final pngBytes = (await composed.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();

        // ✅ PDF page size = image size, không có margin trắng
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(imgW, imgH),
            build: (_) =>
                pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.fill),
          ),
        );
      }

      final output = File(document.path);
      await output.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF saved with overlays');

      // 🔥 FIX: sau khi bake vào PDF, phải xoá overlay tạm
      _pageTextOverlays.clear();
      _pageImageOverlays.clear();

      // 🔥 reload lại page image từ PDF mới đã bake signature
      await _loadPages();

      debugPrint('✅ PDF saved with edits: ${document.path}');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void onDone(BuildContext context) {
    Navigator.pop(context, true);
  }

  // ===== PLACEHOLDER =====
  void combine() {}
  void split() {}
  void bookmark() {}
  void rename() {}
  void setPassword() {}
  void unsetPassword() {}
}
