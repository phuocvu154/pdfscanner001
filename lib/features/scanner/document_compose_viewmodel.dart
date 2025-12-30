import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../documents/document_item.dart';
import '../documents/document_repository.dart';
import '../scanner/document_scanner_service.dart';

class DocumentComposeViewModel extends ChangeNotifier {
  final DocumentRepository _repo;

  final List<String> _imageUris;
  int _currentIndex = 0;
  bool _isProcessing = false;

  String _fileName = '';

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

  // ===== DONE (SAVE PDF) =====
  // Future<DocumentItem> save() async {
  //   _isProcessing = true;
  //   notifyListeners();

  //   try {
  //     final dir = await getApplicationDocumentsDirectory();
  //     final name = _fileName.isNotEmpty
  //         ? _fileName
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

  //     // 🔴 TẠO & LƯU DOCUMENT (SOURCE OF TRUTH)
  //     final doc = _repo.createDocument(
  //       pdfPath: pdfPath,
  //       pageCount: _imageUris.length,
  //       name: name,
  //     );
  //     debugPrint('✅ SAVE PDF OK: ${doc.name} | ${doc.id}');
  //     return doc;
  //   } finally {
  //     _isProcessing = false;
  //     notifyListeners();
  //   }
  // }
  Future<bool> save() async {
  if (_imageUris.isEmpty) return false;

  _isProcessing = true;
  notifyListeners();

  try {
    final dir = await getApplicationDocumentsDirectory();

    final name = _fileName.isNotEmpty
        ? '$_fileName.pdf'
        : 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final pdfPath = '${dir.path}/$name';

    final pdf = pw.Document();

    for (final imagePath in _imageUris) {
      final bytes = File(imagePath).readAsBytesSync();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    // 🔴 SOURCE OF TRUTH DUY NHẤT
    final doc = _repo.createDocument(
      pdfPath: pdfPath,
      pageCount: _imageUris.length,
      name: name,
    );

    debugPrint('✅ SAVE PDF OK: ${doc.name} | ${doc.id}');
    return true;
  } catch (e, s) {
    debugPrint('❌ SAVE PDF FAILED: $e');
    debugPrint('$s');
    return false;
  } finally {
    _isProcessing = false;
    notifyListeners();
  }
}

  

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
}
