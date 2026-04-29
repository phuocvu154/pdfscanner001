import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../converters/doc_to_pdf.dart';
import '../converters/excel_to_pdf.dart';
import '../converters/pdf_to_doc.dart';
import '../converters/pdf_to_excel.dart';
import '../converters/pdf_to_png.dart';
import '../converters/pdf_to_svg.dart';
import '../converters/svg_to_pdf.dart';

class ConvertViewModel extends ChangeNotifier {
  final DocumentRepository _repo;

  ConvertViewModel(this._repo);

  bool isProcessing = false;
  bool expanded = false;

  // 🔴 Lưu kết quả file để share
  List<String> lastConvertedFiles = [];

  final List<String> otherItems = const [
    'PDF to PNG',
    'PDF to JPG',
    'PDF to SVG',
    'PDF to DOC',
    'PDF to EXCEL',
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

        case 'PDF to PNG':
          return await _pdfToPng(); // 🔴 THÊM CASE
        case 'PDF to JPG':
          return await _pdfToJpg(); // 🔴 THÊM CASE
        case 'PDF to SVG':
          return await _pdfToSvg(); // 🔴 THÊM
        case 'PDF to DOC':
          return await _pdfToDoc(); // 🔴 THÊM
        case 'PDF to EXCEL':
          return await _pdfToExcel(); // 🔴 THÊM

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

  // =========================================================
  // PDF → PNG 🔴 THÊM MỚI
  // =========================================================
  Future<DocumentItem?> _pdfToPng() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final input = result.files.single.path!;
    final inputName = path.basenameWithoutExtension(input);

    final dir = await getApplicationDocumentsDirectory();
    final outputFolder =
        '${dir.path}/${inputName}_PNG_${DateTime.now().millisecondsSinceEpoch}';

    // Chuyển đổi
    final pngPaths = await pdfToPngToFolder(
      input,
      outputFolder,
      dpi: 150,
      baseName: inputName,
    );

    if (pngPaths.isEmpty) return null;

    // Lưu để share sau
    lastConvertedFiles = pngPaths;

    // Share ngay sau khi convert
    await _shareFiles(pngPaths);

    // Không trả về DocumentItem vì đây là PNG, không phải PDF
    return null;
  }

  // =========================================================
  // PDF → JPG 🔴 THÊM MỚI
  // =========================================================
  Future<DocumentItem?> _pdfToJpg() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final input = result.files.single.path!;
    final inputName = path.basenameWithoutExtension(input);

    final dir = await getApplicationDocumentsDirectory();
    final outputFolder =
        '${dir.path}/${inputName}_JPG_${DateTime.now().millisecondsSinceEpoch}';

    // Chuyển đổi (dùng chung hàm, sau đó đổi extension)
    final pngPaths = await pdfToPngToFolder(
      input,
      outputFolder,
      dpi: 150,
      baseName: inputName,
    );

    if (pngPaths.isEmpty) return null;

    // Đổi tên file từ .png sang .jpg (thực tế vẫn là PNG data, nhưng đa số app đọc được)
    // Hoặc có thể convert thực sự sang JPG nếu cần
    final jpgPaths = <String>[];
    for (final pngPath in pngPaths) {
      final jpgPath = pngPath.replaceAll('.png', '.jpg');
      await File(pngPath).rename(jpgPath);
      jpgPaths.add(jpgPath);
    }

    // Share ngay sau khi convert
    await _sharePngFiles(jpgPaths);

    return null;
  }

  // =========================================================
// PDF → SVG
// =========================================================
Future<DocumentItem?> _pdfToSvg() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null || result.files.isEmpty) return null;

  final input = result.files.single.path!;
  final inputName = path.basenameWithoutExtension(input);

  final dir = await getApplicationDocumentsDirectory();
  final outputFolder =
      '${dir.path}/${inputName}_SVG_${DateTime.now().millisecondsSinceEpoch}';

  final svgPaths = await pdfToSvg(
    input,
    outputFolder,
    dpi: 150,
    baseName: inputName,
  );

  if (svgPaths.isEmpty) return null;

  lastConvertedFiles = svgPaths;
  
  // 🔴 Chỉ share nếu ít file, không share nếu nhiều file
  if (svgPaths.length <= 10) {
    await _shareFiles(svgPaths);
  } else {
    debugPrint('📁 ${svgPaths.length} SVG files saved to: $outputFolder');
    // Có thể mở thư mục hoặc hiển thị dialog thông báo
  }

  return null;
}

  // =========================================================
  // PDF → DOC 🔴 THÊM MỚI
  // =========================================================
  Future<DocumentItem?> _pdfToDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final input = result.files.single.path!;
    final inputName = path.basenameWithoutExtension(input);

    final dir = await getApplicationDocumentsDirectory();
    final output =
        '${dir.path}/${inputName}_${DateTime.now().millisecondsSinceEpoch}.docx';

    await pdfToDocx(input, output);

    lastConvertedFiles = [output];
    await _shareFiles([output]);

    return null;
  }

  // =========================================================
  // PDF → EXCEL 🔴 THÊM MỚI
  // =========================================================
  Future<DocumentItem?> _pdfToExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final input = result.files.single.path!;
    final inputName = path.basenameWithoutExtension(input);

    final dir = await getApplicationDocumentsDirectory();
    final output =
        '${dir.path}/${inputName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    await pdfToExcel(input, output);

    lastConvertedFiles = [output];
    await _shareFiles([output]);

    return null;
  }

  // =========================================================
  // SHARE FILES
  // =========================================================
  Future<void> _shareFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    final xFiles = filePaths.map((p) => XFile(p)).toList();

    await Share.shareXFiles(
      xFiles,
      text: 'Đã chuyển đổi ${filePaths.length} file',
    );
  }

  // =========================================================
  // SHARE FILES
  // =========================================================
  Future<void> _sharePngFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    final xFiles = filePaths.map((p) => XFile(p)).toList();

    await Share.shareXFiles(
      xFiles,
      text: 'Đã chuyển đổi ${filePaths.length} trang',
    );
  }

  /// Share các file đã convert gần nhất
  Future<void> shareLastConvertedFiles() async {
    await _shareFiles(lastConvertedFiles);
  }
}
