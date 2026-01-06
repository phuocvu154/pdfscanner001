import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../documents/document_item.dart';
import '../documents/document_repository.dart';
import '../pdf/pdf_edit/edit_models.dart';
import 'scan_service.dart';
import 'package:path/path.dart' as path;

class DocumentComposeViewModel extends ChangeNotifier {
  final DocumentRepository _repo;

  final List<String> _imageUris;
  int _currentIndex = 0;
  bool _isProcessing = false;

  String _fileName = '';

  final Map<int, List<TextOverlay>> _pageTextOverlays = {};

  List<TextOverlay> overlaysOfPage(int page) => _pageTextOverlays[page] ?? [];

  DocumentComposeViewModel(List<String> imageUris, this._repo)
    : _imageUris = List.of(imageUris);

  // ===== GETTERS =====
  List<String> get imageUris => List.unmodifiable(_imageUris);
  int get total => _imageUris.length;
  int get currentIndex => _currentIndex;
  bool get isProcessing => _isProcessing;
  String get fileName => _fileName;

  // ===== PAGE =====
  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void deleteCurrent() {
    if (_imageUris.length <= 1) return;

    _imageUris.removeAt(_currentIndex);
    if (_currentIndex >= _imageUris.length) {
      _currentIndex = _imageUris.length - 1;
    }
    notifyListeners();
  }

  // ===== ADD PAGE =====
  Future<void> addPage() async {
    if (_isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final scanner = DocumentScannerService();
      final newImages = await scanner.scan();
      scanner.dispose();

      if (newImages.isNotEmpty) {
        _imageUris.addAll(newImages);
        _currentIndex = _imageUris.length - 1;
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ===== RENAME =====
  void setFileName(String name) {
    _fileName = name.trim();
    notifyListeners();
  }

  // Future<bool> save() async {
  //   if (_imageUris.isEmpty) return false;

  //   _isProcessing = true;
  //   notifyListeners();

  //   try {
  //     final dir = await getApplicationDocumentsDirectory();

  //     final name = _fileName.isNotEmpty
  //         ? '$_fileName.pdf'
  //         : 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

  //     final pdfPath = '${dir.path}/$name';

  //     final pdf = pw.Document();

  //     for (final imagePath in _imageUris) {
  //       final bytes = File(imagePath).readAsBytesSync();
  //       final image = pw.MemoryImage(bytes);

  //       pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
  //     }

  //     final file = File(pdfPath);
  //     await file.writeAsBytes(await pdf.save());

  //     // 🔴 SOURCE OF TRUTH DUY NHẤT
  //     final doc = _repo.createDocument(
  //       pdfPath: pdfPath,
  //       pageCount: _imageUris.length,
  //       name: name,
  //     );

  //     debugPrint('✅ SAVE PDF OK: ${doc.name} | ${doc.id}');
  //     return true;
  //   } catch (e, s) {
  //     debugPrint('❌ SAVE PDF FAILED: $e');
  //     debugPrint('$s');
  //     return false;
  //   } finally {
  //     _isProcessing = false;
  //     notifyListeners();
  //   }
  // }
  // Future<DocumentItem> save() async {
  //   _isProcessing = true;
  //   notifyListeners();

  //   try {
  //     final dir = await getApplicationDocumentsDirectory();
  //     final pdfPath =
  //         '${dir.path}/Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

  //     final pdf = pw.Document();

  //     for (int i = 0; i < _imageUris.length; i++) {
  //       final imageFile = File(_imageUris[i]);
  //       final bytes = await imageFile.readAsBytes();
  //       final image = pw.MemoryImage(bytes);

  //       final overlays = _pageTextOverlays[i] ?? [];

  //       pdf.addPage(
  //         pw.Page(
  //           build: (context) {
  //             return pw.Stack(
  //               children: [
  //                 pw.Positioned.fill(
  //                   child: pw.Image(image, fit: pw.BoxFit.contain),
  //                 ),

  //                 // ===== TEXT OVERLAY =====
  //                 ...overlays.map((t) {
  //                   return pw.Positioned(
  //                     left: t.position.dx * context.page.pageFormat.width,
  //                     top: t.position.dy * context.page.pageFormat.height,
  //                     child: pw.Text(
  //                       t.text,
  //                       style: pw.TextStyle(
  //                         fontSize: t.fontSize,
  //                         color: PdfColor.fromInt(t.color.value),
  //                       ),
  //                     ),
  //                   );
  //                 }),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     }

  //     final file = File(pdfPath);
  //     await file.writeAsBytes(await pdf.save());

  //     final doc = DocumentItem(
  //       id: const Uuid().v4(),
  //       name: path.basename(pdfPath),
  //       path: pdfPath,
  //       createdAt: DateTime.now(),
  //       pageCount: _imageUris.length,
  //     );

  //     await _repo.saveFile(doc);

  //     return doc;
  //   } finally {
  //     _isProcessing = false;
  //     notifyListeners();
  //   }
  // }

  // Future<String> _createPdf() async {
  //   final dir = await getApplicationDocumentsDirectory();

  //   final fileName = _fileName.isNotEmpty
  //       ? _fileName
  //       : 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

  //   final pdfPath = path.join(dir.path, fileName);

  //   final pdf = pw.Document();

  //   for (final imagePath in _imageUris) {
  //     final bytes = File(imagePath).readAsBytesSync();
  //     final image = pw.MemoryImage(bytes);

  //     pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
  //   }

  //   final file = File(pdfPath);
  //   await file.writeAsBytes(await pdf.save());

  //   return pdfPath;
  // }

  void rename(BuildContext context) {
    final controller = TextEditingController(text: _fileName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename file'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter file name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setFileName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  //EDIT Page TEXT OVERLAYS
  void setPageTextOverlays(int pageIndex, List<TextOverlay> overlays) {
    _pageTextOverlays[pageIndex] = List.of(overlays);
    notifyListeners();
  }

  Future<DocumentItem> saveWithEdits() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfPath = '${dir.path}/$fileName';

      final pdf = pw.Document();
      const pageFormat = PdfPageFormat.a4;

      for (int pageIndex = 0; pageIndex < _imageUris.length; pageIndex++) {
        final bytes = await File(_imageUris[pageIndex]).readAsBytes();

        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 1654,
          targetHeight: 2339,
        );

        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, pageFormat.width, pageFormat.height),
        );

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

        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(0, 0, imgW, imgH),
          Rect.fromLTWH(offsetX, offsetY, renderW, renderH),
          Paint(),
        );

        final texts = _pageTextOverlays[pageIndex] ?? [];

        for (final t in texts) {
          final x = offsetX + t.relativePosition.dx * renderW;
          final y = offsetY + t.relativePosition.dy * renderH;

          final painter = TextPainter(
            text: TextSpan(
              text: t.text,
              style: TextStyle(
                fontSize: t.fontSize, // ✅ KHÔNG SCALE
                color: t.color,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          painter.paint(canvas, Offset(x, y));
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

      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      final doc = DocumentItem(
        id: const Uuid().v4(),
        name: fileName,
        path: pdfPath,
        createdAt: DateTime.now(),
        pageCount: _imageUris.length,
      );

      await _repo.saveFile(doc);
      return doc;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
