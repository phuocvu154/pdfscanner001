import 'dart:io';
import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../../scan_result_preview/scan_service.dart';

import '../pdf_edit/image_overlay.dart';
import '../pdf_edit/text_overlay.dart';
import '../pdf_edit_service.dart';


import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'parse_range.dart';

class PdfViewViewModel extends ChangeNotifier {
  late DocumentItem _document;
  final DocumentRepository _repo;

  DocumentItem get document => _document;
  PdfViewViewModel(DocumentItem document, this._repo) {
    _document = document;
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

  Future<List<DocumentItem>> splitByPage() async {
    try {
      final bytes = await File(document.path).readAsBytes();
      final input = PdfDocument(inputBytes: bytes);

      final dir = await getApplicationDocumentsDirectory();
      final results = <DocumentItem>[];

      for (int i = 0; i < input.pages.count; i++) {
        final originalPage = input.pages[i];

        final newDoc = PdfDocument();
        final newPage = newDoc.pages.add();

        final template = originalPage.createTemplate();

        final pageWidth = newPage.getClientSize().width;
        final pageHeight = newPage.getClientSize().height;

        final templateWidth = template.size.width;
        final templateHeight = template.size.height;

        // 🔥 SCALE CHUẨN (FIX LANDSCAPE)
        final scaleX = pageWidth / templateWidth;
        final scaleY = pageHeight / templateHeight;
        final scale = math.min(scaleX, scaleY);

        final drawWidth = templateWidth * scale;
        final drawHeight = templateHeight * scale;

        final offsetX = (pageWidth - drawWidth) / 2;
        final offsetY = (pageHeight - drawHeight) / 2;

        newPage.graphics.drawPdfTemplate(
          template,
          Offset(offsetX, offsetY),
          Size(drawWidth, drawHeight),
        );

        final name = '${document.name.replaceAll('.pdf', '')}_p${i + 1}.pdf';
        final path = '${dir.path}/$name';

        await File(path).writeAsBytes(await newDoc.save());
        newDoc.dispose();

        final docItem = DocumentItem(
          id: const Uuid().v4(),
          name: name,
          path: path,
          createdAt: DateTime.now(),
          pageCount: 1,
        );

        await _repo.saveFile(docItem);
        results.add(docItem);
      }

      input.dispose();
      return results;
    } catch (e) {
      debugPrint('❌ Split error: $e');
      return [];
    }
  }

  Future<List<DocumentItem>> splitByRange(String inputRange) async {
    try {
      final ranges = parseRanges(inputRange);

      final bytes = await File(document.path).readAsBytes();
      final input = PdfDocument(inputBytes: bytes);

      final dir = await getApplicationDocumentsDirectory();
      final results = <DocumentItem>[];

      for (final r in ranges) {
        final newDoc = PdfDocument();

        for (int i = r.start; i <= r.end; i++) {
          if (i >= input.pages.count) break;

          final originalPage = input.pages[i];
          final newPage = newDoc.pages.add();

          final template = originalPage.createTemplate();

          final pageWidth = newPage.getClientSize().width;
          final pageHeight = newPage.getClientSize().height;

          final templateWidth = template.size.width;
          final templateHeight = template.size.height;

          // 🔥 SCALE CHUẨN (FIX LANDSCAPE)
          final scaleX = pageWidth / templateWidth;
          final scaleY = pageHeight / templateHeight;
          final scale = math.min(scaleX, scaleY);

          final drawWidth = templateWidth * scale;
          final drawHeight = templateHeight * scale;

          final offsetX = (pageWidth - drawWidth) / 2;
          final offsetY = (pageHeight - drawHeight) / 2;

          newPage.graphics.drawPdfTemplate(
            template,
            Offset(offsetX, offsetY),
            Size(drawWidth, drawHeight),
          );
        }

        final name =
            '${document.name.replaceAll('.pdf', '')}_${r.start + 1}-${r.end + 1}.pdf';

        final path = '${dir.path}/$name';

        await File(path).writeAsBytes(await newDoc.save());
        newDoc.dispose();

        final docItem = DocumentItem(
          id: const Uuid().v4(),
          name: name,
          path: path,
          createdAt: DateTime.now(),
          pageCount: r.end - r.start + 1,
        );

        await _repo.saveFile(docItem);
        results.add(docItem);
      }

      input.dispose();
      return results;
    } catch (e) {
      debugPrint('❌ Split range error: $e');
      return [];
    }
  }

  Future<DocumentItem?> combineWithCurrent() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedPaths = result.paths.whereType<String>().toList();
      if (pickedPaths.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Combined_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputPath = '${dir.path}/$fileName';

      // 🔥 Tạo PDF mới rỗng
      final outputPdf = PdfDocument();

      // 🔥 Gom tất cả paths: current trước, picked sau
      final allPaths = [document.path, ...pickedPaths];

      for (final path in allPaths) {
        final bytes = await File(path).readAsBytes();
        final srcDoc = PdfDocument(inputBytes: bytes);

        for (int i = 0; i < srcDoc.pages.count; i++) {
          final srcPage = srcDoc.pages[i];
          final newPage = outputPdf.pages.add();

          // Copy nội dung page bằng PdfTemplate
          final template = srcPage.createTemplate();
          newPage.graphics.drawPdfTemplate(template, Offset.zero, srcPage.size);
        }

        srcDoc.dispose();
      }

      // 🔥 Save
      final bytes = await outputPdf.save();
      final pageCount = outputPdf.pages.count;
      outputPdf.dispose();

      await File(outputPath).writeAsBytes(bytes);

      final doc = DocumentItem(
        id: const Uuid().v4(),
        name: fileName,
        path: outputPath,
        createdAt: DateTime.now(),
        pageCount: pageCount,
      );

      await _repo.saveFile(doc);

      return doc;
    } catch (e) {
      debugPrint('❌ Combine error: $e');
      return null;
    }
  }
  // Future<DocumentItem?> combineWithCurrent() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       allowMultiple: true,
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf'],
  //     );

  //     if (result == null || result.files.isEmpty) return null;

  //     final pickedPaths = result.paths.whereType<String>().toList();
  //     if (pickedPaths.isEmpty) return null;

  //     final currentPath = document.path;
  //     final dir = await getApplicationDocumentsDirectory();
  //     final fileName = 'Combined_${DateTime.now().millisecondsSinceEpoch}.pdf';
  //     final outputPath = '${dir.path}/$fileName';

  //     // ✅ current trước → picked phía sau
  //     final inputPaths = [currentPath, ...pickedPaths];

  //     await PdfCombiner.generatePDFFromDocuments(
  //       inputs: inputPaths.map((p) => MergeInput.path(p)).toList(),
  //       outputPath: outputPath,
  //     );

  //     final doc = DocumentItem(
  //       id: const Uuid().v4(),
  //       name: fileName,
  //       path: outputPath,
  //       createdAt: DateTime.now(),
  //       pageCount: 0,
  //     );

  //     await _repo.saveFile(doc);

  //     return doc;
  //   } catch (e) {
  //     debugPrint('❌ Combine error: $e');
  //     return null;
  //   }
  // }

  // Future<DocumentItem?> combine() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       allowMultiple: true,
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf'],
  //     );

  //     if (result == null || result.files.isEmpty) return null;

  //     final files = result.paths.whereType<String>().toList();

  //     if (files.isEmpty) return null;

  //     final pdf = pw.Document();

  //     for (final path in files) {
  //       final bytes = await File(path).readAsBytes();

  //       final raster = await Printing.raster(bytes, dpi: 72).toList();

  //       for (final page in raster) {
  //         final pngBytes = await page.toPng();

  //         pdf.addPage(
  //           pw.Page(build: (_) => pw.Image(pw.MemoryImage(pngBytes))),
  //         );
  //       }
  //     }

  //     final dir = await getApplicationDocumentsDirectory();

  //     final fileName = 'Combined_${DateTime.now().millisecondsSinceEpoch}.pdf';
  //     final outputPath = '${dir.path}/$fileName';

  //     final file = File(outputPath);
  //     await file.writeAsBytes(await pdf.save());

  //     final doc = DocumentItem(
  //       id: const Uuid().v4(),
  //       name: fileName,
  //       path: outputPath,
  //       createdAt: DateTime.now(),
  //       pageCount: 0, // optional
  //     );

  //     await _repo.saveFile(doc);

  //     return doc;
  //   } catch (e) {
  //     debugPrint('❌ Combine error: $e');
  //     return null;
  //   }
  // }

  Future<List<DocumentItem>> splitPdf() async {
    try {
      final bytes = await File(document.path).readAsBytes();

      final PdfDocument input = PdfDocument(inputBytes: bytes);

      final dir = await getApplicationDocumentsDirectory();

      final List<DocumentItem> results = [];

      for (int i = 0; i < input.pages.count; i++) {
        final newDoc = PdfDocument();

        // 🔥 copy từng page
        newDoc.pages.add().graphics.drawPdfTemplate(
          input.pages[i].createTemplate(),
          const Offset(0, 0),
        );

        final fileName =
            '${document.name.replaceAll('.pdf', '')}_p${i + 1}.pdf';

        final path = '${dir.path}/$fileName';

        final file = File(path);
        await file.writeAsBytes(await newDoc.save());

        newDoc.dispose();

        final docItem = DocumentItem(
          id: const Uuid().v4(),
          name: fileName,
          path: path,
          createdAt: DateTime.now(),
          pageCount: 1,
        );

        await _repo.saveFile(docItem);
        results.add(docItem);
      }

      input.dispose();

      return results;
    } catch (e) {
      debugPrint('❌ Split error: $e');
      return [];
    }
  }

  void bookmark() {}
  Future<void> rename(String newName) async {
    try {
      final dir = File(document.path).parent;

      final safeName = newName.replaceAll('.pdf', '');
      final newPath = '${dir.path}/$safeName.pdf';

      // ===== RENAME FILE =====
      final newFile = await File(document.path).rename(newPath);

      final updatedDoc = document.copyWith(
        name: '$safeName.pdf',
        path: newFile.path,
      );

      // ===== UPDATE DB =====
      await _repo.updateDocument(updatedDoc);

      // ===== UPDATE LOCAL =====
      _document = updatedDoc;

      // 🔥 QUAN TRỌNG: reload lại preview từ file mới
      await _loadPages();

      notifyListeners();

      debugPrint('✅ Rename success: $newPath');
    } catch (e) {
      debugPrint('❌ Rename failed: $e');
    }
  }

  Future<DocumentItem?> setPassword(String password) async {
    try {
      final bytes = await File(document.path).readAsBytes();

      final pdf = PdfDocument(inputBytes: bytes);

      // 🔥 SET PASSWORD
      pdf.security.userPassword = password;

      final dir = await getApplicationDocumentsDirectory();
      final newPath =
          '${dir.path}/${document.name.replaceAll('.pdf', '')}_secured.pdf';

      final file = File(newPath);
      await file.writeAsBytes(await pdf.save());

      pdf.dispose();

      final doc = DocumentItem(
        id: const Uuid().v4(),
        name: '${document.name.replaceAll('.pdf', '')}_secured.pdf',
        path: newPath,
        createdAt: DateTime.now(),
        pageCount: document.pageCount,
      );

      await _repo.saveFile(doc);

      return doc;
    } catch (e) {
      debugPrint('❌ Set password error: $e');
      return null;
    }
  }

  Future<DocumentItem?> removePassword(String password) async {
    try {
      final bytes = await File(document.path).readAsBytes();

      // 🔥 mở bằng password
      final pdf = PdfDocument(inputBytes: bytes, password: password);

      // 🔥 remove password
      pdf.security.userPassword = '';

      final dir = await getApplicationDocumentsDirectory();
      final newPath =
          '${dir.path}/${document.name.replaceAll('.pdf', '')}_unlocked.pdf';

      final file = File(newPath);
      await file.writeAsBytes(await pdf.save());

      pdf.dispose();

      final doc = DocumentItem(
        id: const Uuid().v4(),
        name: '${document.name.replaceAll('.pdf', '')}_unlocked.pdf',
        path: newPath,
        createdAt: DateTime.now(),
        pageCount: document.pageCount,
      );

      await _repo.saveFile(doc);

      return doc;
    } catch (e) {
      debugPrint('❌ Remove password error: $e');
      return null;
    }
  }
}
