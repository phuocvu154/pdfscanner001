import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class SignatureTextEditor extends StatefulWidget {
  final void Function(String imagePath) onDone;

  const SignatureTextEditor({super.key, required this.onDone});

  @override
  State<SignatureTextEditor> createState() => _SignatureTextEditorState();
}

class _SignatureTextEditorState extends State<SignatureTextEditor> {
  final controller = TextEditingController(text: 'Your Signature');
  final repaintKey = GlobalKey();

  String fontFamily = 'Pacifico';
  Color color = Colors.black;
  double fontSize = 64;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Text Signature'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _onDone,
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.transparent,
                child: Text(
                  controller.text,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),

        _textInput(),
        _fontPicker(),
        _colorPicker(),
        _sizeSlider(),
      ],
    ),
  );
}
Widget _textInput() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Signature text',
        border: OutlineInputBorder(),
      ),
    ),
  );
}
Widget _fontPicker() {
  const fonts = ['Pacifico', 'DancingScript', 'GreatVibes'];

  return SizedBox(
    height: 80,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: fonts.map((f) {
        return GestureDetector(
          onTap: () => setState(() => fontFamily = f),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: fontFamily == f ? Colors.blue : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Signature',
              style: TextStyle(fontFamily: f, fontSize: 24),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
Widget _colorPicker() {
  final colors = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: colors.map((c) {
      return GestureDetector(
        onTap: () => setState(() => color = c),
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: c == color ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
Widget _sizeSlider() {
  return Slider(
    min: 32,
    max: 120,
    value: fontSize,
    onChanged: (v) => setState(() => fontSize = v),
  );
}
Future<void> _onDone() async {
  if (controller.text.trim().isEmpty) return;

  final boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = (await image.toByteData(
    format: ImageByteFormat.png,
  ))!
      .buffer
      .asUint8List();

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/sig_text_${DateTime.now().millisecondsSinceEpoch}.png',
  );

  await file.writeAsBytes(bytes);
  widget.onDone(file.path);
  Navigator.pop(context);
}

}

