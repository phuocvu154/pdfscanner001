import 'dart:io';
import 'package:printing/printing.dart';

class DocToPdfConverter {
  static Future<void> convert(File docFile) async {
    await Printing.layoutPdf(
      onLayout: (_) async => await docFile.readAsBytes(),
    );
  }
}
