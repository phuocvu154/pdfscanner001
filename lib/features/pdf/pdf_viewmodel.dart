import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../documents/document__viewmodel.dart';
import '../documents/document_repository.dart';
import 'pdf_repository.dart';

class PdfViewModel extends ChangeNotifier {
  final PdfRepository pdfRepo;
  final DocumentRepository docRepo;

  PdfViewModel(this.pdfRepo, this.docRepo);

  bool loading = false;
  String? lastPdfPath;

  Future<void> generateAndSavePdf(
    List<String> images,
    BuildContext context,
  ) async {
    loading = true;
    notifyListeners();

    try {
      final pdfPath = await pdfRepo.createPdfFromImages(images);
      lastPdfPath = pdfPath;

      final doc = docRepo.addDocument(
        pdfPath: pdfPath,
        pageCount: images.length,
      );

      final docsVm = Provider.of<DocumentsViewModel>(context, listen: false);
      docsVm.addDocument(doc);

      loading = false;
      notifyListeners();

      Navigator.pushNamed(context, '/pdfPreview', arguments: pdfPath);
    } catch (e) {
      loading = false;
      notifyListeners();
    }
  }
}
