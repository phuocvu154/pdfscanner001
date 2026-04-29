import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Chuyển SVG sang PDF
Future<String> svgToPdf(String svgPath, String outputPath) async {
  // 1️⃣ Đọc file SVG
  final svgString = await File(svgPath).readAsString();

  // 2️⃣ Tạo PDF
  final pdf = pw.Document();

  // 3️⃣ Parse SVG và thêm vào PDF
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Center(
          child: pw.SvgImage(
            svg: svgString,
            fit: pw.BoxFit.contain,
          ),
        );
      },
    ),
  );

  // 4️⃣ Lưu PDF
  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());

  return outputPath;
}

/// Chuyển nhiều SVG sang PDF (mỗi SVG = 1 trang)
Future<String> svgsToPdf(List<String> svgPaths, String outputPath) async {
  final pdf = pw.Document();

  for (final svgPath in svgPaths) {
    final svgString = await File(svgPath).readAsString();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Center(
            child: pw.SvgImage(
              svg: svgString,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());

  return outputPath;
}