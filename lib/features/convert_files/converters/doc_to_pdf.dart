import 'dart:convert'; // 🔴 THÊM IMPORT NÀY
import 'dart:io';

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

/// Chuyển DOCX sang PDF (hỗ trợ tiếng Việt + multi-page)
Future<String> docxToPdf(String docxPath, String outputPath) async {
  await _loadFonts();

  final bytes = File(docxPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  // Tìm file document.xml
  final documentFile = archive.files.firstWhere(
    (f) => f.name == 'word/document.xml',
    orElse: () => throw Exception('Không tìm thấy document.xml'),
  );

  // 🔴 SỬA: Dùng utf8.decode() thay vì String.fromCharCodes()
  final xmlString = utf8.decode(documentFile.content as List<int>);
  final xml = XmlDocument.parse(xmlString);

  // Parse paragraphs
  final paragraphs = _parseParagraphs(xml);

  // Tạo PDF với MultiPage
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      maxPages: 100,
      header: (context) => _buildHeader(context),
      footer: (context) => _buildFooter(context),
      build: (context) => paragraphs,
    ),
  );

  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());

  return outputPath;
}

/// Header cho mỗi trang
pw.Widget _buildHeader(pw.Context context) {
  if (context.pageNumber == 1) return pw.SizedBox();

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.only(bottom: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'Trang ${context.pageNumber}',
          style: pw.TextStyle(
            font: _regularFont,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
      ],
    ),
  );
}

/// Footer cho mỗi trang
pw.Widget _buildFooter(pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(
            font: _regularFont,
            fontSize: 9,
            color: PdfColors.grey500,
          ),
        ),
      ],
    ),
  );
}

/// Parse paragraphs từ XML
List<pw.Widget> _parseParagraphs(XmlDocument xml) {
  final widgets = <pw.Widget>[];

  final paragraphs = xml.findAllElements('w:p');

  for (final para in paragraphs) {
    // Kiểm tra page break
    final hasPageBreak = _hasPageBreak(para);

    if (hasPageBreak) {
      widgets.add(pw.NewPage());
      continue;
    }

    // Kiểm tra heading
    final headingLevel = _getHeadingLevel(para);

    final runs = para.findAllElements('w:r');
    final spans = <pw.TextSpan>[];

    for (final run in runs) {
      // Bỏ qua page break trong run
      if (run.findAllElements('w:br').any(
            (br) => br.getAttribute('w:type') == 'page',
          )) {
        continue;
      }

      final textElements = run.findAllElements('w:t');
      if (textElements.isEmpty) continue;

      final text = textElements.map((e) => e.innerText).join();
      if (text.isEmpty) continue;

      final runProps = run.findElements('w:rPr').firstOrNull;
      final style = _parseRunStyle(runProps, headingLevel);

      spans.add(pw.TextSpan(text: text, style: style));
    }

    if (spans.isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
    } else {
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