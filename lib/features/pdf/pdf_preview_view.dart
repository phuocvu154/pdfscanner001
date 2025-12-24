import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewView extends StatelessWidget {
  final String path;

  const PdfPreviewView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xem PDF"),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(path)], text: "Tài liệu đã scan");
            },
          ),
        ],
      ),
      body: PDFView(filePath: path, enableSwipe: true, swipeHorizontal: false),
    );
  }
}