import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class SvgToPdfConverter {
  static Future<File> convert(File svgFile) async {
    final svgString = await svgFile.readAsString();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.SvgImage(svg: svgString),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/svg_${DateTime.now().millisecondsSinceEpoch}.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
