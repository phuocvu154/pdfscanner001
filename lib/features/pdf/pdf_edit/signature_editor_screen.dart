import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'signature_item.dart';
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
            onPressed: () {}, // dùng khi vẽ tay
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== DRAW AREA (vẽ tay – sẽ làm tiếp nếu bạn muốn) =====
          Expanded(
            child: Center(
              child: Text(
                'Sign here',
                style: TextStyle(color: Colors.grey.shade400),
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
}
