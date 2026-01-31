import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ExcelToPdfConverter {
  static Future<File> convert(File csvFile) async {
    final lines = await csvFile.readAsLines();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Table.fromTextArray(
          data: lines.map((e) => e.split(',')).toList(),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/excel_${DateTime.now().millisecondsSinceEpoch}.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
