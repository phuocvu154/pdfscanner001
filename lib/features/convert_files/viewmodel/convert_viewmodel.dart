import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../converters/image_to_pdf.dart';

class ConvertViewModel extends ChangeNotifier {
  final DocumentRepository _repo;

  ConvertViewModel(this._repo);

  bool isProcessing = false;
  bool expanded = false;

  final List<String> otherItems = const [
    'PDF to PNG',
    'PDF to JPG',
    'PDF to DOC',
    'PDF to SVG',
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
        default:
          return null;
      }
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  // =========================================================
  // IMAGE → PDF
  // =========================================================
  Future<DocumentItem?> _imageToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return null;

    

    

    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: 'Converted.pdf',
      path: '/path/to/pdf',
      createdAt: DateTime.now(),
      pageCount: 3,
    );

    await _repo.saveFile(doc);
    return doc;
  }

  // =========================================================
  // SVG → PDF
  // =========================================================
  Future<DocumentItem?> _svgToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );

    if (result == null || result.files.isEmpty) return null;

    // TODO: dùng flutter_svg + pdf để render SVG
    // Tạm thời báo chưa hỗ trợ
    debugPrint('SVG to PDF not implemented yet');
    return null;
  }

  // =========================================================
  // DOC → PDF
  // =========================================================
  Future<DocumentItem?> _docToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (result == null) return null;

    // TODO: dùng LibreOffice / cloud / backend
    debugPrint('DOC to PDF not implemented yet');
    return null;
  }

  // =========================================================
  // EXCEL → PDF
  // =========================================================
  Future<DocumentItem?> _excelToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result == null) return null;

    // TODO: dùng syncfusion_xlsio + pdf
    debugPrint('EXCEL to PDF not implemented yet');
    return null;
  }
}
