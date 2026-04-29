import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class DocumentScannerService {
  final _scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 10,
    ),
  );

  Future<List<String>> scan() async {
    final result = await _scanner.scanDocument();

    if (result.images.isEmpty) return [];

    return result.images;
  }

  void dispose() {
    _scanner.close();
  }
}
