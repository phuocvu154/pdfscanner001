import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Font? _regularFont;
pw.Font? _boldFont;

/// Load font tiếng Việt
Future<void> _loadFonts() async {
  if (_regularFont != null && _boldFont != null) return;

  try {
    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
    
    debugPrint('✅ Fonts loaded successfully');
  } catch (e) {
    debugPrint('❌ Error loading fonts: $e');
    // Fallback to default fonts
    _regularFont = pw.Font.helvetica();
    _boldFont = pw.Font.helveticaBold();
  }
}

/// Chuyển Excel sang PDF (multi-sheet + tiếng Việt)
Future<String> excelToPdf(String excelPath, String outputPath) async {
  await _loadFonts();

  // 1️⃣ Đọc file Excel
  final bytes = File(excelPath).readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  // 2️⃣ Tạo PDF
  final pdf = pw.Document();

  // 3️⃣ Xử lý từng sheet
  for (final sheetName in excel.tables.keys) {
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.isEmpty) continue;

    // Lấy số cột tối đa
    int maxColumns = 0;
    for (final row in sheet.rows) {
      if (row.length > maxColumns) maxColumns = row.length;
    }

    if (maxColumns == 0) continue;

    // Chuyển dữ liệu sang List<List<String>>
    final tableData = <List<String>>[];

    for (final row in sheet.rows) {
      final rowData = <String>[];
      for (int i = 0; i < maxColumns; i++) {
        if (i < row.length && row[i] != null) {
          rowData.add(_getCellValue(row[i]));
        } else {
          rowData.add('');
        }
      }
      tableData.add(rowData);
    }

    // Chia nhỏ data nếu quá nhiều hàng
    final headers = tableData.isNotEmpty ? tableData.first : <String>[];
    final dataRows = tableData.length > 1 ? tableData.sublist(1) : <List<String>>[];

    const int rowsPerPage = 25;
    final chunks = <List<List<String>>>[];

    for (int i = 0; i < dataRows.length; i += rowsPerPage) {
      final end = (i + rowsPerPage > dataRows.length) ? dataRows.length : i + rowsPerPage;
      chunks.add(dataRows.sublist(i, end));
    }

    if (chunks.isEmpty) {
      chunks.add([]);
    }

    // Thêm page cho mỗi chunk
    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Sheet: $sheetName',
                      style: pw.TextStyle(
                        font: _boldFont,
                        fontSize: 14,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Trang ${chunkIndex + 1}/${chunks.length}',
                      style: pw.TextStyle(
                        font: _regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Table
                pw.Expanded(
                  child: _buildTable(headers, chunk),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  // 4️⃣ Lưu PDF
  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());

  return outputPath;
}

/// Build table với font tiếng Việt
pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(
      color: PdfColors.grey400,
      width: 0.5,
    ),
    headerStyle: pw.TextStyle(
      font: _boldFont,
      fontSize: 8,
      color: PdfColors.white,
    ),
    headerDecoration: const pw.BoxDecoration(
      color: PdfColors.blue700,
    ),
    cellStyle: pw.TextStyle(
      font: _regularFont,
      fontSize: 7,
    ),
    cellPadding: const pw.EdgeInsets.all(3),
    cellHeight: 20,
    oddRowDecoration: const pw.BoxDecoration(
      color: PdfColors.grey100,
    ),
  );
}

/// Lấy giá trị cell (đảm bảo UTF-8)
String _getCellValue(Data? cell) {
  if (cell == null || cell.value == null) return '';

  final value = cell.value;

  if (value is TextCellValue) {
    return value.value.toString();
  } else if (value is IntCellValue) {
    return value.value.toString();
  } else if (value is DoubleCellValue) {
    final num = value.value;
    if (num == num.roundToDouble()) {
      return num.toInt().toString();
    }
    return num.toStringAsFixed(2);
  } else if (value is BoolCellValue) {
    return value.value ? 'Có' : 'Không';
  } else if (value is DateCellValue) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  } else if (value is TimeCellValue) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  } else if (value is DateTimeCellValue) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  } else if (value is FormulaCellValue) {
    return value.formula;
  }

  return value.toString();
}
// ```

// ---

// **Kiểm tra các bước sau:**

// **1. Đảm bảo có file font trong `assets/fonts/`:**
// ```
// assets/
//   fonts/
//     Roboto-Regular.ttf
//     Roboto-Bold.ttf
//     Roboto-Italic.ttf
//     Roboto-BoldItalic.ttf