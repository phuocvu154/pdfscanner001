import 'dart:io';
import 'dart:ui' as ui;
import 'package:pdf_render_maintained/pdf_render_maintained.dart';
import 'package:path_provider/path_provider.dart';

class PdfToImageConverter {
  static Future<List<File>> convert(File pdfFile) async {
    final doc = await PdfDocument.openFile(pdfFile.path);
    final dir = await getTemporaryDirectory();
    final files = <File>[];

    for (int i = 1; i <= doc.pageCount; i++) {
      final page = await doc.getPage(i);
      final pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
      );

      // Chuyển đổi sang PNG bytes
      final image = await pageImage.createImageDetached();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final file = File('${dir.path}/page_$i.png');
      await file.writeAsBytes(pngBytes);
      files.add(file);

      image.dispose();
      pageImage.dispose();
    }

    doc.dispose();
    return files;
  }
}
