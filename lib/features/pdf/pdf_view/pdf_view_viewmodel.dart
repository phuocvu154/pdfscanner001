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

  final List<Uint8List> _pages = [];
  final List<String> _pageImagePaths = []; // 🔴 THÊM: lưu path của từng page

  final Map<int, List<TextOverlay>> _pageTextOverlays = {};
  final Map<int, List<ImageOverlay>> _pageImageOverlays = {};

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isProcessing = false;

  // ===== GETTERS =====
  List<Uint8List> get pages => _pages;
  List<String> get pageImagePaths => _pageImagePaths; // 🔴 THÊM
  int get total => _pages.length;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isAddingPage => _isProcessing; // backward compatible

  List<TextOverlay> textOverlaysOfPage(int page) =>
      _pageTextOverlays[page] ?? [];
  List<ImageOverlay> imageOverlaysOfPage(int page) =>
      _pageImageOverlays[page] ?? [];

  // ===== LOAD PAGES =====
  Future<void> _loadPages() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pages.clear();
      _pageImagePaths.clear();

      // 🔴 DEBUG: Kiểm tra document.path
      debugPrint('📂 Loading PDF from: ${document.path}');

      if (!File(document.path).existsSync()) {
        debugPrint('❌ PDF file not found!');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final bytes = await File(document.path).readAsBytes();

      debugPrint('📄 PDF size: ${bytes.length} bytes');

      final raster = Printing.raster(bytes, dpi: 200);

      int pageIndex = 0;
      await for (final page in raster) {
        final pngBytes = await page.toPng();
        _pages.add(pngBytes);

        // 🔴 Tạo unique temp file path
        final imagePath =
            '${tempDir.path}/pdf_page_${document.id}_$pageIndex.png';
        await File(imagePath).writeAsBytes(pngBytes);
        _pageImagePaths.add(imagePath);

        debugPrint('✅ Page $pageIndex saved to: $imagePath');

        pageIndex++;
      }

      debugPrint('✅ Total pages loaded: ${_pages.length}');
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
    if (_pages.length <= 1) return;

    _pages.removeAt(_currentIndex);
    _pageImagePaths.removeAt(_currentIndex);
    _pageTextOverlays.remove(_currentIndex);
    _pageImageOverlays.remove(_currentIndex);

    _shiftOverlayIndices(_currentIndex);

    if (_currentIndex >= _pages.length) {
      _currentIndex = _pages.length - 1;
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
      _currentIndex = _pages.length - 1;
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
    // Nếu không có edit gì thì không cần save
    if (_pageTextOverlays.isEmpty && _pageImageOverlays.isEmpty) {
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      const pageFormat = PdfPageFormat.a4;
      final pdf = pw.Document();

      // 🔴 SỬA: Dùng _pageImagePaths thay vì document.path
      for (int pageIndex = 0; pageIndex < _pageImagePaths.length; pageIndex++) {
        final bytes = await File(_pageImagePaths[pageIndex]).readAsBytes();

        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        final imgW = uiImage.width.toDouble();
        final imgH = uiImage.height.toDouble();

        final scale = math.min(
          pageFormat.width / imgW,
          pageFormat.height / imgH,
        );

        final renderW = imgW * scale;
        final renderH = imgH * scale;

        final offsetX = (pageFormat.width - renderW) / 2;
        final offsetY = (pageFormat.height - renderH) / 2;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, pageFormat.width, pageFormat.height),
        );

        // ===== DRAW IMAGE =====
        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(0, 0, imgW, imgH),
          Rect.fromLTWH(offsetX, offsetY, renderW, renderH),
          Paint(),
        );

        // ===== DRAW TEXT =====
        final texts = _pageTextOverlays[pageIndex] ?? [];
        for (final t in texts) {
          final fontSize = t.fontScale * renderW;

          canvas.save();
          canvas.translate(
            offsetX + t.relativePosition.dx * renderW,
            offsetY + t.relativePosition.dy * renderH,
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

        // ===== DRAW IMAGE OVERLAY =====
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

          final scalePx = img.scale * renderW;

          canvas.save();
          canvas.translate(centerX, centerY);
          canvas.rotate(img.rotation);
          canvas.scale(scalePx / overlayW, scalePx / overlayW);

          canvas.drawImage(
            overlayImage,
            Offset(-overlayW / 2, -overlayH / 2),
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
            build: (_) => pw.Image(pw.MemoryImage(pngBytes)),
          ),
        );
      }

      // 🔴 Overwrite original PDF file
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
