import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

pw.Font? _regularFont;
pw.Font? _boldFont;
pw.Font? _italicFont;
pw.Font? _boldItalicFont;

/// Load font tiếng Việt
Future<void> _loadFonts() async {
  if (_regularFont != null) return;

  final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
  final boldItalicData = await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf');

  _regularFont = pw.Font.ttf(regularData);
  _boldFont = pw.Font.ttf(boldData);
  _italicFont = pw.Font.ttf(italicData);
  _boldItalicFont = pw.Font.ttf(boldItalicData);
}

/// Chuyển DOCX sang PDF (hỗ trợ tiếng Việt + ảnh)
Future<String> docxToPdf(String docxPath, String outputPath) async {
  await _loadFonts();

  final bytes = File(docxPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  // 1️⃣ Extract images từ DOCX
  final images = _extractImages(archive);

  // 2️⃣ Extract relationships (để map rId -> image path)
  final relationships = _extractRelationships(archive);

  // 3️⃣ Tìm file document.xml
  final documentFile = archive.files.firstWhere(
    (f) => f.name == 'word/document.xml',
    orElse: () => throw Exception('Không tìm thấy document.xml'),
  );

  final xmlString = utf8.decode(documentFile.content as List<int>);
  final xml = XmlDocument.parse(xmlString);

  // 4️⃣ Parse content (text + images)
  final contentWidgets = _parseDocumentContent(xml, images, relationships);

  // 5️⃣ Tạo PDF
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      maxPages: 200,
      build: (context) => contentWidgets,
    ),
  );

  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());

  return outputPath;
}

/// Extract tất cả images từ DOCX
Map<String, Uint8List> _extractImages(Archive archive) {
  final images = <String, Uint8List>{};

  for (final file in archive.files) {
    if (file.name.startsWith('word/media/') && !file.isFile) continue;
    if (file.name.startsWith('word/media/')) {
      final fileName = file.name.replaceFirst('word/media/', '');
      images[fileName] = Uint8List.fromList(file.content as List<int>);
    }
  }

  return images;
}

/// Extract relationships từ document.xml.rels
Map<String, String> _extractRelationships(Archive archive) {
  final relationships = <String, String>{};

  final relsFile = archive.files.firstWhere(
    (f) => f.name == 'word/_rels/document.xml.rels',
    orElse: () => ArchiveFile('', 0, []),
  );

  if (relsFile.content == null || (relsFile.content as List).isEmpty) {
    return relationships;
  }

  try {
    final xmlString = utf8.decode(relsFile.content as List<int>);
    final xml = XmlDocument.parse(xmlString);

    for (final rel in xml.findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');

      if (id != null && target != null && target.contains('media/')) {
        // Extract filename from path like "media/image1.png"
        final fileName = target.replaceFirst('media/', '');
        relationships[id] = fileName;
      }
    }
  } catch (e) {
    // Ignore parsing errors
  }

  return relationships;
}

/// Parse document content (text + images)
List<pw.Widget> _parseDocumentContent(
  XmlDocument xml,
  Map<String, Uint8List> images,
  Map<String, String> relationships,
) {
  final widgets = <pw.Widget>[];

  final paragraphs = xml.findAllElements('w:p');

  for (final para in paragraphs) {
    // Kiểm tra page break
    if (_hasPageBreak(para)) {
      widgets.add(pw.NewPage());
      continue;
    }

    // Kiểm tra heading
    final headingLevel = _getHeadingLevel(para);

    // Parse runs (text + images)
    final runs = para.findAllElements('w:r');
    final spans = <pw.TextSpan>[];
    final inlineImages = <pw.Widget>[];

    for (final run in runs) {
      // Kiểm tra có ảnh không
      final drawing = run.findAllElements('w:drawing').firstOrNull;
      if (drawing != null) {
        final imageWidget = _parseDrawing(drawing, images, relationships);
        if (imageWidget != null) {
          inlineImages.add(imageWidget);
        }
        continue;
      }

      // Kiểm tra có ảnh dạng cũ (w:pict) không
      final pict = run.findAllElements('w:pict').firstOrNull;
      if (pict != null) {
        final imageWidget = _parsePict(pict, images, relationships);
        if (imageWidget != null) {
          inlineImages.add(imageWidget);
        }
        continue;
      }

      // Parse text
      final textElements = run.findAllElements('w:t');
      if (textElements.isEmpty) continue;

      final text = textElements.map((e) => e.innerText).join();
      if (text.isEmpty) continue;

      final runProps = run.findElements('w:rPr').firstOrNull;
      final style = _parseRunStyle(runProps, headingLevel);

      spans.add(pw.TextSpan(text: text, style: style));
    }

    // Thêm ảnh trước
    for (final img in inlineImages) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Center(child: img),
        ),
      );
    }

    // Thêm text
    if (spans.isEmpty && inlineImages.isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
    } else if (spans.isNotEmpty) {
      final paraProps = para.findElements('w:pPr').firstOrNull;
      final alignment = _parseAlignment(paraProps);
      final spacing = _parseSpacing(paraProps);

      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(
            bottom: spacing['after'] ?? 6,
            top: spacing['before'] ?? 0,
          ),
          child: pw.RichText(
            text: pw.TextSpan(children: spans),
            textAlign: alignment,
          ),
        ),
      );
    }
  }

  return widgets;
}

/// Parse w:drawing element để lấy ảnh
pw.Widget? _parseDrawing(
  XmlElement drawing,
  Map<String, Uint8List> images,
  Map<String, String> relationships,
) {
  try {
    // Tìm a:blip element chứa rId
    final blip = drawing.findAllElements('a:blip').firstOrNull;
    if (blip == null) return null;

    // Lấy rId (có thể là r:embed hoặc r:link)
    final rId = blip.getAttribute('r:embed') ?? blip.getAttribute('r:link');
    if (rId == null) return null;

    // Map rId -> filename
    final fileName = relationships[rId];
    if (fileName == null) return null;

    // Lấy image bytes
    final imageBytes = images[fileName];
    if (imageBytes == null) return null;

    // Lấy kích thước từ wp:extent (EMU)
    final extent = drawing.findAllElements('wp:extent').firstOrNull;
    double? width;
    double? height;

    if (extent != null) {
      final cx = extent.getAttribute('cx');
      final cy = extent.getAttribute('cy');

      if (cx != null) {
        // Convert EMU to points (914400 EMU = 1 inch = 72 points)
        width = int.parse(cx) / 914400 * 72;
      }
      if (cy != null) {
        height = int.parse(cy) / 914400 * 72;
      }
    }

    // Giới hạn kích thước tối đa
    const maxWidth = 500.0;
    const maxHeight = 700.0;

    if (width != null && width > maxWidth) {
      final ratio = maxWidth / width;
      width = maxWidth;
      if (height != null) height = height * ratio;
    }

    if (height != null && height > maxHeight) {
      final ratio = maxHeight / height;
      height = maxHeight;
      if (width != null) width = width * ratio;
    }

    return pw.Image(
      pw.MemoryImage(imageBytes),
      width: width ?? 200,
      height: height,
      fit: pw.BoxFit.contain,
    );
  } catch (e) {
    return null;
  }
}

/// Parse w:pict element (định dạng ảnh cũ)
pw.Widget? _parsePict(
  XmlElement pict,
  Map<String, Uint8List> images,
  Map<String, String> relationships,
) {
  try {
    // Tìm v:imagedata hoặc r:id
    final imageData = pict.findAllElements('v:imagedata').firstOrNull;
    if (imageData == null) return null;

    final rId = imageData.getAttribute('r:id');
    if (rId == null) return null;

    final fileName = relationships[rId];
    if (fileName == null) return null;

    final imageBytes = images[fileName];
    if (imageBytes == null) return null;

    return pw.Image(
      pw.MemoryImage(imageBytes),
      width: 200,
      fit: pw.BoxFit.contain,
    );
  } catch (e) {
    return null;
  }
}

/// Kiểm tra page break
bool _hasPageBreak(XmlElement para) {
  final breaks = para.findAllElements('w:br');
  for (final br in breaks) {
    if (br.getAttribute('w:type') == 'page') {
      return true;
    }
  }

  final paraProps = para.findElements('w:pPr').firstOrNull;
  if (paraProps != null) {
    if (paraProps.findElements('w:pageBreakBefore').isNotEmpty) {
      return true;
    }
  }

  return false;
}

/// Lấy heading level
int _getHeadingLevel(XmlElement para) {
  final paraProps = para.findElements('w:pPr').firstOrNull;
  if (paraProps == null) return 0;

  final pStyle = paraProps.findElements('w:pStyle').firstOrNull;
  if (pStyle == null) return 0;

  final styleVal = pStyle.getAttribute('w:val') ?? '';

  final match = RegExp(r'[Hh]eading\s?(\d)').firstMatch(styleVal);
  if (match != null) {
    return int.tryParse(match.group(1) ?? '0') ?? 0;
  }

  return 0;
}

/// Parse style của run
pw.TextStyle _parseRunStyle(XmlElement? runProps, int headingLevel) {
  bool isBold = headingLevel > 0;
  bool isItalic = false;
  bool isUnderline = false;
  double fontSize = 12;
  PdfColor color = PdfColors.black;

  if (headingLevel > 0) {
    switch (headingLevel) {
      case 1:
        fontSize = 24;
        break;
      case 2:
        fontSize = 20;
        break;
      case 3:
        fontSize = 16;
        break;
      default:
        fontSize = 14;
    }
  }

  if (runProps != null) {
    isBold = isBold || runProps.findElements('w:b').isNotEmpty;
    isItalic = runProps.findElements('w:i').isNotEmpty;
    isUnderline = runProps.findElements('w:u').isNotEmpty;

    final szElement = runProps.findElements('w:sz').firstOrNull;
    if (szElement != null && headingLevel == 0) {
      final szValue = szElement.getAttribute('w:val');
      if (szValue != null) {
        fontSize = (int.tryParse(szValue) ?? 24) / 2;
      }
    }

    final colorElement = runProps.findElements('w:color').firstOrNull;
    if (colorElement != null) {
      final colorValue = colorElement.getAttribute('w:val');
      if (colorValue != null && colorValue != 'auto') {
        color = _parseColor(colorValue);
      }
    }
  }

  pw.Font? font;
  if (isBold && isItalic) {
    font = _boldItalicFont;
  } else if (isBold) {
    font = _boldFont;
  } else if (isItalic) {
    font = _italicFont;
  } else {
    font = _regularFont;
  }

  return pw.TextStyle(
    font: font,
    fontSize: fontSize,
    color: color,
    decoration: isUnderline ? pw.TextDecoration.underline : null,
  );
}

/// Parse alignment
pw.TextAlign _parseAlignment(XmlElement? paraProps) {
  if (paraProps == null) return pw.TextAlign.left;

  final jcElement = paraProps.findElements('w:jc').firstOrNull;
  if (jcElement == null) return pw.TextAlign.left;

  final jcValue = jcElement.getAttribute('w:val');

  switch (jcValue) {
    case 'center':
      return pw.TextAlign.center;
    case 'right':
      return pw.TextAlign.right;
    case 'both':
    case 'distribute':
      return pw.TextAlign.justify;
    default:
      return pw.TextAlign.left;
  }
}

/// Parse spacing
Map<String, double> _parseSpacing(XmlElement? paraProps) {
  final result = <String, double>{'before': 0, 'after': 6};

  if (paraProps == null) return result;

  final spacingElement = paraProps.findElements('w:spacing').firstOrNull;
  if (spacingElement == null) return result;

  final beforeVal = spacingElement.getAttribute('w:before');
  if (beforeVal != null) {
    result['before'] = (int.tryParse(beforeVal) ?? 0) / 20;
  }

  final afterVal = spacingElement.getAttribute('w:after');
  if (afterVal != null) {
    result['after'] = (int.tryParse(afterVal) ?? 120) / 20;
  }

  return result;
}

/// Parse color từ hex string
PdfColor _parseColor(String hex) {
  try {
    hex = hex.replaceAll('#', '');

    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return PdfColor.fromInt((0xFF << 24) | (r << 16) | (g << 8) | b);
    }
  } catch (_) {}

  return PdfColors.black;
}
// ```

// ---

// **Tóm tắt tính năng mới:**

// | Tính năng | Mô tả |
// |-----------|-------|
// | `_extractImages()` | Extract tất cả ảnh từ `word/media/` |
// | `_extractRelationships()` | Map rId → filename từ `document.xml.rels` |
// | `_parseDrawing()` | Parse ảnh dạng mới (`w:drawing` + `a:blip`) |
// | `_parsePict()` | Parse ảnh dạng cũ (`w:pict` + `v:imagedata`) |
// | Kích thước ảnh | Convert từ EMU sang points, giới hạn max 500x700 |

// ---

// **Cấu trúc DOCX được xử lý:**
// ```
// input.docx (ZIP)
// ├── word/
// │   ├── document.xml          (chứa text + image references)
// │   ├── _rels/
// │   │   └── document.xml.rels (map rId → media/imageX.png)
// │   └── media/
// │       ├── image1.png
// │       ├── image2.jpg
// │       └── ...