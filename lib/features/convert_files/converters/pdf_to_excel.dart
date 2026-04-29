import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Chuyển PDF sang Excel
Future<String> pdfToExcel(String pdfPath, String outputPath) async {
  try {
    final bytes = await File(pdfPath).readAsBytes();

    // 1️⃣ Extract text từ PDF
    final pdfDoc = PdfDocument(inputBytes: bytes);
    final pageTexts = <List<String>>[];

    for (int i = 0; i < pdfDoc.pages.count; i++) {
      final textExtractor = PdfTextExtractor(pdfDoc);
      final text = textExtractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );

      // Chia text thành các dòng
      final lines = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      pageTexts.add(lines);
    }

    pdfDoc.dispose();

    // 2️⃣ Tạo Excel workbook bằng 'excel' package
    final excel = Excel.createExcel();

    for (int pageIndex = 0; pageIndex < pageTexts.length; pageIndex++) {
      final lines = pageTexts[pageIndex];

      // Tạo sheet cho mỗi trang
      final sheetName = 'Trang ${pageIndex + 1}';
      final sheet = excel[sheetName];

      // Ghi dữ liệu vào sheet
      for (int rowIndex = 0; rowIndex < lines.length; rowIndex++) {
        final line = lines[rowIndex];

        // Thử tách theo tab hoặc nhiều spaces (có thể là bảng)
        final cells = _splitLineIntoCells(line);

        for (int colIndex = 0; colIndex < cells.length; colIndex++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            cells[colIndex],
          );
        }
      }
    }

    // Xóa sheet mặc định 'Sheet1' nếu có
    if (excel.sheets.containsKey('Sheet1') && pageTexts.isNotEmpty) {
      excel.delete('Sheet1');
    }

    // 3️⃣ Lưu file
    final excelBytes = excel.encode();
    if (excelBytes != null) {
      await File(outputPath).writeAsBytes(excelBytes);
    }

    debugPrint('✅ PDF to Excel saved: $outputPath');
    return outputPath;
  } catch (e, s) {
    debugPrint('❌ PDF to Excel error: $e');
    debugPrint('$s');
    rethrow;
  }
}

/// Tách dòng text thành các cells
List<String> _splitLineIntoCells(String line) {
  // Thử tách theo tab trước
  if (line.contains('\t')) {
    return line.split('\t').map((s) => s.trim()).toList();
  }

  // Thử tách theo nhiều spaces (>= 2 spaces)
  final parts = line.split(RegExp(r'\s{2,}'));
  if (parts.length > 1) {
    return parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  // Không tách được, trả về cả dòng
  return [line.trim()];
}
