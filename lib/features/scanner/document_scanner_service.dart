import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class DocumentScannerService {
  final DocumentScanner _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 5,
      isGalleryImport: false,
    ),
  );

  Future<List<String>> scan() async {
    final result = await _scanner.scanDocument();

    // user cancel
    if (result.images.isEmpty) {
      return [];
    }

    // MLKit trả về imageUri (String)
    return result.images;
  }

  void dispose() {
    _scanner.close();
  }
}
