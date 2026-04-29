import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Chuyển PDF sang PNG (trả về danh sách đường dẫn ảnh PNG)
Future<List<String>> pdfToPng(String pdfPath, {double dpi = 150}) async {
  final pngPaths = <String>[];

  try {
    final bytes = await File(pdfPath).readAsBytes();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Render PDF thành các trang PNG
    final raster = Printing.raster(bytes, dpi: dpi);

    int pageIndex = 0;
    await for (final page in raster) {
      final pngBytes = await page.toPng();

      final pngPath = '${dir.path}/pdf_page_${timestamp}_$pageIndex.png';
      await File(pngPath).writeAsBytes(pngBytes);
      pngPaths.add(pngPath);

      debugPrint('✅ Page $pageIndex saved to: $pngPath');
      pageIndex++;
    }

    debugPrint('✅ Total pages converted: ${pngPaths.length}');
  } catch (e, s) {
    debugPrint('❌ PDF to PNG error: $e');
    debugPrint('$s');
  }

  return pngPaths;
}

/// Chuyển PDF sang PNG và lưu vào thư mục chỉ định
Future<List<String>> pdfToPngToFolder(
  String pdfPath,
  String outputFolder, {
  double dpi = 150,
  String? baseName,
}) async {
  final pngPaths = <String>[];

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

      final pngPath = '$outputFolder/${name}_${pageIndex + 1}.png';
      await File(pngPath).writeAsBytes(pngBytes);
      pngPaths.add(pngPath);

      pageIndex++;
    }

    debugPrint('✅ Saved ${pngPaths.length} PNG files to: $outputFolder');
  } catch (e, s) {
    debugPrint('❌ PDF to PNG error: $e');
    debugPrint('$s');
  }

  return pngPaths;
}