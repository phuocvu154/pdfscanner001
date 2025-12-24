import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import 'scaned_document.dart';

class ScanViewModel extends ChangeNotifier {
  bool isScanning = false;
  ScannedDocument? lastDocument;
  String? error;

  Future<void> scan() async {
    isScanning = true;
    error = null;
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
    } catch (e) {
      error = e.toString();
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  void exit(BuildContext context) {
    isScanning = false;
    notifyListeners();
    Navigator.of(context).pop();
  }
}
