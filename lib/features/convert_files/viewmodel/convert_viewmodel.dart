import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../converters/doc_to_pdf.dart';
import '../converters/excel_to_pdf.dart';
import '../converters/svg_to_pdf.dart';

class ConvertViewModel extends ChangeNotifier {
  final DocumentRepository _repo;

  ConvertViewModel(this._repo);

  bool isProcessing = false;
  bool expanded = false;

  final List<String> otherItems = const [
    'PDF to PNG',
    'PDF to JPG',
    'SVG to PDF',
    'DOC to PDF',
    'EXCEL to PDF',
  ];

  void toggleExpand() {
    expanded = !expanded;
    notifyListeners();
  }

  // =========================================================
  // MAIN ENTRY
  // =========================================================
  Future<DocumentItem?> onSelect(String title) async {
    isProcessing = true;
    notifyListeners();

    try {
      switch (title) {
        case 'PNG to PDF':
        case 'JPG to PDF':
          return await _imageToPdf();
        case 'SVG to PDF':
          return await _svgToPdf();
        case 'DOC to PDF':
          return await _docToPdf();
        case 'EXCEL to PDF':
          return await _excelToPdf();

        default:
          return null;
      }
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  // =========================================================
  // IMAGE → PDF (REAL IMPLEMENTATION)
  // =========================================================
  Future<DocumentItem?> _imageToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return null;

    final pdf = pw.Document();

    for (final file in result.files) {
      final bytes = await File(file.path!).readAsBytes();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
    }

    final dir = await getApplicationDocumentsDirectory();
    final pdfPath =
        '${dir.path}/Convert_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: path.basename(pdfPath),
      path: pdfPath,
      createdAt: DateTime.now(),
      pageCount: result.files.length,
    );

    await _repo.saveFile(doc);

    return doc;
  }

  Future<DocumentItem?> _docToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result == null) return null;

    final input = result.files.single.path!;

    final dir = await getApplicationDocumentsDirectory();
    final output =
        '${dir.path}/Doc_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await docxToPdf(input, output);

    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: 'Converted.pdf',
      path: output,
      createdAt: DateTime.now(),
      pageCount: 1,
    );

    await _repo.saveFile(doc);
    return doc;
  }

  Future<DocumentItem?> _excelToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result == null) return null;

    final input = result.files.single.path!;

    final dir = await getApplicationDocumentsDirectory();
    final output =
        '${dir.path}/Excel_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await excelToPdf(input, output);

    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: 'Converted.pdf',
      path: output,
      createdAt: DateTime.now(),
      pageCount: 1,
    );

    await _repo.saveFile(doc);
    return doc;
  }

  // =========================================================
  // SVG → PDF 🔴 THÊM MỚI
  // =========================================================
  Future<DocumentItem?> _svgToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );

    if (result == null || result.files.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${dir.path}/SVG_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final svgPaths = result.files.map((f) => f.path!).toList();

    // Chuyển đổi
    if (svgPaths.length == 1) {
      await svgToPdf(svgPaths.first, outputPath);
    } else {
      await svgsToPdf(svgPaths, outputPath);
    }

    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: path.basename(outputPath),
      path: outputPath,
      createdAt: DateTime.now(),
      pageCount: svgPaths.length,
    );

    await _repo.saveFile(doc);
    return doc;
  }
}
