import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Chuyển PDF sang DOCX (bao gồm cả text và ảnh)
Future<String> pdfToDocx(String pdfPath, String outputPath) async {
  try {
    final bytes = await File(pdfPath).readAsBytes();
    final pdfDoc = PdfDocument(inputBytes: bytes);

    final pageContents = <_PageContent>[];

    // 1️⃣ Extract text từ PDF
    for (int i = 0; i < pdfDoc.pages.count; i++) {
      final textExtractor = PdfTextExtractor(pdfDoc);
      final text = textExtractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );
      pageContents.add(_PageContent(text: text, imageBytes: null));
    }

    pdfDoc.dispose();

    // 2️⃣ Render mỗi trang PDF thành ảnh PNG
    final raster = Printing.raster(bytes, dpi: 100);
    int pageIndex = 0;

    await for (final page in raster) {
      final pngBytes = await page.toPng();

      if (pageIndex < pageContents.length) {
        pageContents[pageIndex] = _PageContent(
          text: pageContents[pageIndex].text,
          imageBytes: pngBytes,
        );
      }

      debugPrint('✅ Page $pageIndex rendered: ${pngBytes.length} bytes');
      pageIndex++;
    }

    // 3️⃣ Tạo DOCX với text và ảnh
    final docxBytes = _createDocxWithImages(pageContents);

    // 4️⃣ Lưu file
    await File(outputPath).writeAsBytes(docxBytes);

    debugPrint('✅ PDF to DOCX saved: $outputPath');
    return outputPath;
  } catch (e, s) {
    debugPrint('❌ PDF to DOCX error: $e');
    debugPrint('$s');
    rethrow;
  }
}

/// Nội dung của mỗi trang PDF
class _PageContent {
  final String text;
  final Uint8List? imageBytes;

  _PageContent({required this.text, required this.imageBytes});
}

/// Tạo file DOCX với text và ảnh
Uint8List _createDocxWithImages(List<_PageContent> pageContents) {
  final archive = Archive();

  // Collect images
  final images = <_ImageInfo>[];
  for (int i = 0; i < pageContents.length; i++) {
    if (pageContents[i].imageBytes != null) {
      images.add(
        _ImageInfo(
          id: i + 1,
          rId: 'rId${i + 2}', // rId1 reserved
          bytes: pageContents[i].imageBytes!,
          pageIndex: i,
        ),
      );
    }
  }

  // 1️⃣ [Content_Types].xml
  final contentTypesXml = _buildContentTypes(images);
  archive.addFile(
    ArchiveFile(
      '[Content_Types].xml',
      utf8.encode(contentTypesXml).length,
      utf8.encode(contentTypesXml),
    ),
  );

  // 2️⃣ _rels/.rels
  final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
  archive.addFile(
    ArchiveFile(
      '_rels/.rels',
      utf8.encode(relsXml).length,
      utf8.encode(relsXml),
    ),
  );

  // 3️⃣ word/_rels/document.xml.rels
  final documentRelsXml = _buildDocumentRels(images);
  archive.addFile(
    ArchiveFile(
      'word/_rels/document.xml.rels',
      utf8.encode(documentRelsXml).length,
      utf8.encode(documentRelsXml),
    ),
  );

  // 4️⃣ word/document.xml
  final documentXml = _buildDocument(pageContents, images);
  archive.addFile(
    ArchiveFile(
      'word/document.xml',
      utf8.encode(documentXml).length,
      utf8.encode(documentXml),
    ),
  );

  // 5️⃣ Thêm các file ảnh vào word/media/
  for (final img in images) {
    archive.addFile(
      ArchiveFile('word/media/image${img.id}.png', img.bytes.length, img.bytes),
    );
  }

  // Encode thành bytes
  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes!);
}

/// Thông tin ảnh
class _ImageInfo {
  final int id;
  final String rId;
  final Uint8List bytes;
  final int pageIndex;

  _ImageInfo({
    required this.id,
    required this.rId,
    required this.bytes,
    required this.pageIndex,
  });
}

/// Build [Content_Types].xml
String _buildContentTypes(List<_ImageInfo> images) {
  final imageOverrides = images
      .map(
        (img) =>
            '<Override PartName="/word/media/image${img.id}.png" ContentType="image/png"/>',
      )
      .join('\n  ');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  $imageOverrides
</Types>''';
}

/// Build word/_rels/document.xml.rels
String _buildDocumentRels(List<_ImageInfo> images) {
  final imageRels = images
      .map(
        (img) =>
            '<Relationship Id="${img.rId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image${img.id}.png"/>',
      )
      .join('\n  ');

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  $imageRels
</Relationships>''';
}

/// Build word/document.xml
String _buildDocument(
  List<_PageContent> pageContents,
  List<_ImageInfo> images,
) {
  final paragraphs = StringBuffer();

  for (int pageIndex = 0; pageIndex < pageContents.length; pageIndex++) {
    final content = pageContents[pageIndex];

    // Thêm tiêu đề trang nếu nhiều hơn 1 trang
    if (pageContents.length > 1) {
      paragraphs.write('''
      <w:p>
        <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
        <w:r><w:t>Trang ${pageIndex + 1}</w:t></w:r>
      </w:p>
      ''');
    }

    // Thêm ảnh của trang này
    final pageImage = images
        .where((img) => img.pageIndex == pageIndex)
        .firstOrNull;
    if (pageImage != null) {
      paragraphs.write(_buildImageParagraph(pageImage));
    }

    // Thêm text
    final lines = content.text.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) {
        paragraphs.write('<w:p/>');
      } else {
        final escapedText = _escapeXml(line);
        paragraphs.write('''
        <w:p>
          <w:r><w:t xml:space="preserve">$escapedText</w:t></w:r>
        </w:p>
        ''');
      }
    }

    // Page break giữa các trang (trừ trang cuối)
    if (pageIndex < pageContents.length - 1) {
      paragraphs.write('''
      <w:p>
        <w:r><w:br w:type="page"/></w:r>
      </w:p>
      ''');
    }
  }

  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
            xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    $paragraphs
  </w:body>
</w:document>''';
}

/// Build paragraph chứa ảnh
String _buildImageParagraph(_ImageInfo img) {
  // Kích thước: A4 width ≈ 6 inches = 5486400 EMU
  const int widthEmu = 5486400;
  const int heightEmu = 7772400; // A4 ratio

  return '''
  <w:p>
    <w:r>
      <w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="$widthEmu" cy="$heightEmu"/>
          <wp:docPr id="${img.id}" name="Picture ${img.id}"/>
          <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:nvPicPr>
                  <pic:cNvPr id="${img.id}" name="image${img.id}.png"/>
                  <pic:cNvPicPr/>
                </pic:nvPicPr>
                <pic:blipFill>
                  <a:blip r:embed="${img.rId}"/>
                  <a:stretch>
                    <a:fillRect/>
                  </a:stretch>
                </pic:blipFill>
                <pic:spPr>
                  <a:xfrm>
                    <a:off x="0" y="0"/>
                    <a:ext cx="$widthEmu" cy="$heightEmu"/>
                  </a:xfrm>
                  <a:prstGeom prst="rect">
                    <a:avLst/>
                  </a:prstGeom>
                </pic:spPr>
              </pic:pic>
            </a:graphicData>
          </a:graphic>
        </wp:inline>
      </w:drawing>
    </w:r>
  </w:p>
  ''';
}

/// Escape các ký tự đặc biệt XML
String _escapeXml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
