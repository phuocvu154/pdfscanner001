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
      _pageImagePaths.clear();

      debugPrint('📂 Loading PDF from: ${document.path}');

      if (!File(document.path).existsSync()) {
        debugPrint('❌ PDF file not found!');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final bytes = await File(document.path).readAsBytes();

      debugPrint('📄 PDF size: ${bytes.length} bytes');

      // 🔴 DPI thấp để tránh OOM (72-100 là đủ cho preview)
      final raster = Printing.raster(bytes, dpi: 150);

      int pageIndex = 0;
      await for (final page in raster) {
        final pngBytes = await page.toPng();

        final imagePath =
            '${tempDir.path}/pdf_page_${document.id}_$pageIndex.png';
        await File(imagePath).writeAsBytes(pngBytes);
        _pageImagePaths.add(imagePath);

        debugPrint('✅ Page $pageIndex saved');
        pageIndex++;
      }

      debugPrint('✅ Total pages loaded: ${_pageImagePaths.length}');
    } catch (e, s) {
      debugPrint('❌ Load PDF failed: $e');
      debugPrint('$s');
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
    if (_pageTextOverlays.isEmpty && _pageImageOverlays.isEmpty) {
      return;
    }

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

        final baseScale = math.min(
          pageFormat.width / imgW,
          pageFormat.height / imgH,
        );

        final renderW = imgW * baseScale;
        final renderH = imgH * baseScale;

        final offsetX = (pageFormat.width - renderW) / 2;
        final offsetY = (pageFormat.height - renderH) / 2;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, pageFormat.width, pageFormat.height),
        );

        // ===== DRAW BASE PAGE IMAGE =====
        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(0, 0, imgW, imgH),
          Rect.fromLTWH(offsetX, offsetY, renderW, renderH),
          Paint(),
        );

        // ===== DRAW TEXT OVERLAYS =====
        final texts = _pageTextOverlays[pageIndex] ?? [];
        for (final t in texts) {
          final fontSize = t.fontScale * renderW;

          final dx = offsetX + t.relativePosition.dx * renderW;
          final dy = offsetY + t.relativePosition.dy * renderH;

          canvas.save();
          canvas.translate(dx, dy);
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

        // ===== DRAW IMAGE OVERLAYS =====
        final images = _pageImageOverlays[pageIndex] ?? [];
        for (final img in images) {
          final centerX = offsetX + img.relativePosition.dx * renderW;
          final centerY = offsetY + img.relativePosition.dy * renderH;

          final overlayBytes = await File(img.imagePath).readAsBytes();
          final overlayCodec = await ui.instantiateImageCodec(overlayBytes);
          final overlayFrame = await overlayCodec.getNextFrame();
          final overlayImage = overlayFrame.image;

          final overlayW = overlayImage.width.toDouble();
          final overlayH = overlayImage.height.toDouble();

          // img.scale được hiểu là tỉ lệ theo chiều rộng ảnh nền render
          final displayWidth = img.scale * renderW;
          final aspectRatio = overlayH / overlayW;
          final displayHeight = displayWidth * aspectRatio;

          canvas.save();
          canvas.translate(centerX, centerY);
          canvas.rotate(img.rotation);

          canvas.drawImageRect(
            overlayImage,
            Rect.fromLTWH(0, 0, overlayW, overlayH),
            Rect.fromCenter(
              center: Offset.zero,
              width: displayWidth,
              height: displayHeight,
            ),
            Paint(),
          );

          canvas.restore();
        }

        final picture = recorder.endRecording();
        final composed = await picture.toImage(
          pageFormat.width.toInt(),
          pageFormat.height.toInt(),
        );

        final pngBytes = (await composed.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (_) =>
                pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain),
          ),
        );
      }

      final file = File(document.path);
      await file.writeAsBytes(await pdf.save());

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
