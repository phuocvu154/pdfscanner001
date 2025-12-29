import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../documents/document_item.dart';
import '../../scanner/document_scanner_service.dart';

import '../pdf_edit_service.dart';

class PdfViewViewModel extends ChangeNotifier {
  final DocumentItem document;

  PdfViewViewModel(this.document) {
    _loadPages();
  }

  final List<Uint8List> _pages = [];
  int currentIndex = 0;
  bool isAddingPage = false;

  List<Uint8List> get pages => _pages;
  int get total => _pages.length;

  Future<void> _loadPages() async {
    _pages.clear();

    final bytes = await File(document.path).readAsBytes();
    final raster = Printing.raster(bytes, dpi: 150);

    await for (final page in raster) {
      _pages.add(await page.toPng());
    }

    notifyListeners();
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  // ===== ACTIONS =====

  void deleteCurrent() {
    if (_pages.isEmpty) return;
    _pages.removeAt(currentIndex);
    if (currentIndex >= _pages.length) {
      currentIndex = _pages.length - 1;
    }
    notifyListeners();
  }

  Future<void> addPage() async {
    isAddingPage = true;
    notifyListeners();

    final scanner = DocumentScannerService();
    final images = await scanner.scan();
    scanner.dispose();

    if (images.isEmpty) {
      isAddingPage = false;
      notifyListeners();
      return;
    }

    final editor = PdfEditService();
    await editor.appendImagesToPdf(pdfPath: document.path, imagePaths: images);

    await _loadPages();

    isAddingPage = false;
    notifyListeners();
  }

  void share() async {
    await Printing.sharePdf(
      bytes: await File(document.path).readAsBytes(),
      filename: document.name,
    );
  }

  void onDone(BuildContext context) {
    Navigator.pop(context, true); // 🔴 trả kết quả
  }

  // ===== PLACEHOLDER =====
  void combine() {}
  void split() {}
  void bookmark() {}
  void rename() {}
  void setPassword() {}
  void unsetPassword() {}
}
