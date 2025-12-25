import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../documents/document_item.dart';
import '../documents/document_repository.dart';
import '../scanner/document_scanner_service.dart';
import '../scanner/scaned_document.dart';

class ScanResultViewModel extends ChangeNotifier {

  ScannedDocument? lastDocument;

  final List<String> _imageUris;

  final DocumentRepository _repository;

  int _currentIndex = 0;
  bool _isAddingPage = false;

  ScanResultViewModel(this._imageUris, this._repository);

  List<String> get imageUris => List.unmodifiable(_imageUris);
  int get currentIndex => _currentIndex;
  int get total => _imageUris.length;
  bool get isAddingPage => _isAddingPage;

  Future<void> onDone(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = '${dir.path}/$fileName';

    final pdf = pw.Document();

    for (final imagePath in _imageUris) {
      final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
    }

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    final _uuid = const Uuid();

    final pdfModel = DocumentItem(
      name: fileName,
      path: pdfPath,
      createdAt: DateTime.now(),
      pageCount: _imageUris.length,
      id: _uuid.v4(),
    );

    await _repository.saveFile(pdfModel);

    Navigator.pop(context); // quay về Home
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void deleteCurrent() {
    _imageUris.removeAt(_currentIndex);
    if (_currentIndex >= _imageUris.length) {
      _currentIndex = _imageUris.length - 1;
    }
    notifyListeners();
  }

  /// 🟢 ADD PAGE = quét thêm trang
  Future<void> addPage() async {
    if (_isAddingPage) return;

    _isAddingPage = true;
    notifyListeners();

    try {
      // 1. Tạo options cho scanner
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg, // hoặc DocumentFormat.pdf
        mode: ScannerMode.full, // UI có filter, crop, etc.
        pageLimit: 10, // tối đa 10 trang
        isGalleryImport: true, // cho phép chọn từ gallery
      );

      // 2. Tạo instance scanner
      final scanner = DocumentScanner(options: options);

      // 3. Mở UI Scan của ML Kit
      final DocumentScanningResult result = await scanner.scanDocument();

      // 4. Lấy data trả về
      final pdf = result.pdf; // đối tượng Pdf (có thể null nếu chọn jpeg)
      final images = result.images; // List<String> path ảnh đã scan

      lastDocument = ScannedDocument(
        imagePaths: images ?? [],
        hasPdf: pdf != null,
      );
      await scanner.close();
      // final newImages = await _scannerService.scan();

      if (images.isNotEmpty) {
        _imageUris.addAll(images);
        _currentIndex = _imageUris.length - 1;
      }
    } catch (e) {
      debugPrint('Add page error: $e');
    } finally {
      _isAddingPage = false;
      notifyListeners();
    }
  }

  /// 🟢 DONE = kết thúc flow
  void done(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void share() {
    // TODO: gắn share_plus
  }

  void combine() {}
  void split() {}
  void bookmark() {}
  void rename() {}
  void setPassword() {}
  void unsetPassword() {}
}
