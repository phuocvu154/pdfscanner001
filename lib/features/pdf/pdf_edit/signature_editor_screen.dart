import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'signature_canvas.dart';
import 'signature_item.dart';
import 'signature_path_point.dart';
import 'signature_repository.dart';

class SignatureResult {
  final String imagePath;
  SignatureResult(this.imagePath);
}

class SignatureEditorScreen extends StatefulWidget {
  const SignatureEditorScreen({super.key});

  @override
  State<SignatureEditorScreen> createState() => _SignatureEditorScreenState();
}

class _SignatureEditorScreenState extends State<SignatureEditorScreen> {
  final repo = SignatureRepository();
  Color color = Colors.black;

  List<SignatureItem> saved = [];

  List<SignaturePoint> _points = [];
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    repo.loadAll().then((v) => setState(() => saved = v));
  }

  void _pickFromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    final savedPath = await repo.save(File(img.path));
    Navigator.pop(context, SignatureResult(savedPath));
  }

  void _scanCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);
    if (img == null) return;

    final savedPath = await repo.save(File(img.path));
    Navigator.pop(context, SignatureResult(savedPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add signature'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_points.isEmpty) return;

              final path = await _exportSignature();

              if (context.mounted) {
                Navigator.pop(context, SignatureResult(path));
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _points.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== DRAW AREA (vẽ tay – sẽ làm tiếp nếu bạn muốn) =====
          // Expanded(
          //   child: Center(
          //     child: Text(
          //       'Sign here',
          //       style: TextStyle(color: Colors.grey.shade400),
          //     ),
          //   ),
          // ),
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                onPanStart: (d) {
                  setState(() {
                    _points.add(SignaturePoint(d.localPosition));
                  });
                },
                onPanUpdate: (d) {
                  setState(() {
                    _points.add(SignaturePoint(d.localPosition));
                  });
                },
                onPanEnd: (_) {
                  _points.add(SignaturePoint.breakPoint());
                },
                child: Container(
                  color: Colors.transparent, // Colors.white,
                  child: SignatureCanvas(points: _points, color: color),
                ),
              ),
            ),
          ),

          // ===== COLOR =====
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in [
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                ])
                  GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: color == c ? 2 : 0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ===== ACTIONS =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _action(Icons.image, 'Collection', _pickFromGallery),
                _action(Icons.camera_alt, 'Scan from camera', _scanCamera),
              ],
            ),
          ),

          // ===== SAVED SIGNATURES =====
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: saved.length,
              itemBuilder: (_, i) {
                final s = saved[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, SignatureResult(s.imagePath));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.file(File(s.imagePath)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(icon: Icon(icon), onPressed: onTap),
        Text(label),
      ],
    );
  }

  Future<String> _exportSignature() async {
    if (_points.isEmpty) {
      throw Exception('No signature points');
    }

    // Lấy các điểm thật, bỏ break point
    final realPoints = _points
        .where((p) => !p.isBreak)
        .map((p) => p.point)
        .toList();

    if (realPoints.isEmpty) {
      throw Exception('No drawable signature points');
    }

    double minX = realPoints.first.dx;
    double maxX = realPoints.first.dx;
    double minY = realPoints.first.dy;
    double maxY = realPoints.first.dy;

    for (final p in realPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    const padding = 24.0;

    final cropLeft = (minX - padding).clamp(0.0, double.infinity);
    final cropTop = (minY - padding).clamp(0.0, double.infinity);
    final cropRight = maxX + padding;
    final cropBottom = maxY + padding;

    final cropWidth = (cropRight - cropLeft).clamp(1.0, double.infinity);
    final cropHeight = (cropBottom - cropTop).clamp(1.0, double.infinity);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, cropWidth, cropHeight));

    // 🔥 KHÔNG vẽ nền trắng
    // Canvas mặc định trong suốt

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];

      if (!p1.isBreak && !p2.isBreak) {
        canvas.drawLine(
          Offset(p1.point.dx - cropLeft, p1.point.dy - cropTop),
          Offset(p2.point.dx - cropLeft, p2.point.dy - cropTop),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();

    final image = await picture.toImage(cropWidth.ceil(), cropHeight.ceil());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final bytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final sigDir = Directory('${dir.path}/signatures');
    if (!sigDir.existsSync()) {
      sigDir.createSync(recursive: true);
    }

    final file = File(
      '${sigDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(bytes);

    debugPrint('✅ Signature exported: ${file.path}');
    debugPrint('✅ Signature crop size: ${cropWidth} x $cropHeight');

    return file.path;
  }
}
