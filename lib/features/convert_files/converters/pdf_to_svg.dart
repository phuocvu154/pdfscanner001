import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

/// Chuyển PDF sang SVG
/// Lưu ý: Không thể convert trực tiếp PDF sang SVG vector
/// Giải pháp: Render PDF thành ảnh rồi embed vào SVG
Future<List<String>> pdfToSvg(
  String pdfPath,
  String outputFolder, {
  double dpi = 150,
  String? baseName,
}) async {
  final svgPaths = <String>[];

  try {
    final bytes = await File(pdfPath).readAsBytes();

    // Tạo thư mục nếu chưa có
    final outputDir = Directory(outputFolder);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final name = baseName ?? 'page';
    final raster = Printing.raster(bytes, dpi: dpi);

    int pageIndex = 0;
    await for (final page in raster) {
      final pngBytes = await page.toPng();
      final width = page.width;
      final height = page.height;

      // Tạo SVG với embedded image (base64)
      final base64Image = base64Encode(pngBytes);
      final svgContent = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="$width" height="$height" viewBox="0 0 $width $height">
  <image width="$width" height="$height" 
         xlink:href="data:image/png;base64,$base64Image"/>
</svg>''';

      final svgPath = '$outputFolder/${name}_${pageIndex + 1}.svg';
      await File(svgPath).writeAsString(svgContent);
      svgPaths.add(svgPath);

      debugPrint('✅ Page $pageIndex saved to: $svgPath');
      pageIndex++;
    }

    debugPrint('✅ Total SVG files: ${svgPaths.length}');
  } catch (e, s) {
    debugPrint('❌ PDF to SVG error: $e');
    debugPrint('$s');
  }

  return svgPaths;
}