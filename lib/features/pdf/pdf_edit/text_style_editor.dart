import 'package:flutter/material.dart';
import 'text_overlay.dart';

class TextStyleEditor extends StatefulWidget {
  final TextOverlay initial;
  final ValueChanged<TextOverlay> onDone;
  final VoidCallback? onDelete; // ✅ THÊM DÒNG NÀY

  const TextStyleEditor({
    super.key,
    required this.initial,
    required this.onDone,
    this.onDelete, // ✅ THÊM DÒNG NÀY
  });

  @override
  State<TextStyleEditor> createState() => _TextStyleEditorState();
}

class _TextStyleEditorState extends State<TextStyleEditor> {
  late TextEditingController _controller;
  late double _fontScale;
  late Color _color;
  late String _fontFamily;

  final _fonts = const ['Roboto', 'Arial', 'Times New Roman', 'Courier New'];

  final _colors = const [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.text);
    _fontScale = widget.initial.fontScale;
    _color = widget.initial.color;
    _fontFamily = widget.initial.fontFamily;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Edit Text',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      widget.onDone(
                        widget.initial.copyWith(
                          text: _controller.text,
                          fontScale: _fontScale,
                          color: _color,
                          fontFamily: _fontFamily,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ===== TEXT INPUT =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // ===== FONT SIZE =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Size'),
                  Expanded(
                    child: Slider(
                      value: _fontScale,
                      min: 0.02,
                      max: 0.12,
                      divisions: 20,
                      onChanged: (v) => setState(() => _fontScale = v),
                    ),
                  ),
                ],
              ),
            ),

            // ===== COLOR PICKER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _colors.map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: _color == c ? 3 : 1,
                          color: _color == c ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ===== FONT FAMILY =====
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _fonts.map((font) {
                  final selected = font == _fontFamily;

                  return GestureDetector(
                    onTap: () => setState(() => _fontFamily = font),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.blue.shade50
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(font, style: TextStyle(fontFamily: font)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: widget.onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),

                const Spacer(),

                ElevatedButton(
                  onPressed: () {
                    widget.onDone;

                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
