import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfEditService {
  Future<void> appendImagesToPdf({
    required String pdfPath,
    required List<String> imagePaths,
  }) async {
    final pdf = pw.Document();

    // 1️⃣ RENDER PDF CŨ → ẢNH (PHẢI DÙNG for + await)
    final raster = Printing.raster(await File(pdfPath).readAsBytes(), dpi: 200);

    await for (final page in raster) {
      final image = pw.MemoryImage(await page.toPng());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    // 2️⃣ ADD PAGE MỚI
    for (final path in imagePaths) {
      final image = pw.MemoryImage(File(path).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    // 3️⃣ GHI ĐÈ PDF (ĐẢM BẢO XONG HẾT)
    await File(pdfPath).writeAsBytes(await pdf.save());
  }
}
