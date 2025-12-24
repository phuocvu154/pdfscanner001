import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfRepository {
  Future<String> createPdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final image = pw.MemoryImage(File(path).readAsBytesSync());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image));
          },
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
}