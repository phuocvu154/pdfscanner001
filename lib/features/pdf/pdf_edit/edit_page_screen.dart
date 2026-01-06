import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'edit_models.dart';
import 'edit_page_viewmodel.dart';

class EditPageScreen extends StatelessWidget {
  final String imagePath;
  final int pageIndex;
  final List<TextOverlay> initialTexts;

  const EditPageScreen({
    super.key,
    required this.imagePath,
    required this.pageIndex,
    required this.initialTexts,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EditPageViewModel(imagePath: imagePath, initialTexts: initialTexts),
      child: _EditView(pageIndex: pageIndex),
    );
  }
}

class _EditView extends StatelessWidget {
  final int pageIndex;

  const _EditView({required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditPageViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit page ${pageIndex + 1}'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: vm.undo),
          IconButton(icon: const Icon(Icons.redo), onPressed: vm.redo),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageFile = File(vm.imagePath);

          return FutureBuilder<ImageInfo>(
            future: _getImageInfo(Image.file(imageFile)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final imageSize = Size(
                snapshot.data!.image.width.toDouble(),
                snapshot.data!.image.height.toDouble(),
              );

              final fitted = applyBoxFit(
                BoxFit.contain,
                imageSize,
                constraints.biggest,
              );

              final renderSize = fitted.destination;

              final offsetX = (constraints.maxWidth - renderSize.width) / 2;
              final offsetY = (constraints.maxHeight - renderSize.height) / 2;

              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // ===== IMAGE =====
                        Positioned(
                          left: offsetX,
                          top: offsetY,
                          width: renderSize.width,
                          height: renderSize.height,
                          child: Image.file(imageFile, fit: BoxFit.contain),
                        ),

                        // ===== TEXT LAYER =====
                        ...vm.texts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final t = entry.value;

                          return Positioned(
                            left:
                                offsetX +
                                t.relativePosition.dx * renderSize.width,
                            top:
                                offsetY +
                                t.relativePosition.dy * renderSize.height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanUpdate: (details) {
                                final dx = details.delta.dx / renderSize.width;
                                final dy = details.delta.dy / renderSize.height;

                                vm.moveTextRelative(i, Offset(dx, dy));
                              },
                              onDoubleTap: () =>
                                  _showEditTextDialog(context, vm, i),
                              child: Text(
                                t.text,
                                style: TextStyle(
                                  fontSize: t.fontSize,
                                  color: t.color,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.6,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // ===== TOOLBAR =====
                  _EditToolbar(renderSize: renderSize),

                  // ===== DONE =====
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, vm.texts);
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ================= TOOLBAR =================

class _EditToolbar extends StatelessWidget {
  final Size renderSize;

  const _EditToolbar({required this.renderSize});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditPageViewModel>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tool(Icons.text_fields, 'Add Text', () {
            _showAddTextDialog(context, vm);
          }),
          _tool(Icons.image, 'Image', () {}),
          _tool(Icons.edit, 'Signature', () {}),
        ],
      ),
    );
  }
}

Widget _tool(IconData icon, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

// ================= ADD TEXT =================

Future<ImageInfo> _getImageInfo(Image image) {
  final completer = Completer<ImageInfo>();
  image.image
      .resolve(const ImageConfiguration())
      .addListener(
        ImageStreamListener((info, _) {
          completer.complete(info);
        }),
      );
  return completer.future;
}

void _showAddTextDialog(BuildContext context, EditPageViewModel vm) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add text'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter text'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) return;

            // ✅ CHUẨN: vị trí tương đối giữa ảnh
            vm.addText(controller.text.trim(), const Offset(0.5, 0.5));

            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ================= EDIT TEXT =================

void _showEditTextDialog(
  BuildContext context,
  EditPageViewModel vm,
  int index,
) {
  final text = vm.texts[index];
  final controller = TextEditingController(text: text.text);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit text'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () {
            vm.deleteText(index);
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: () {
            vm.updateText(index, text.copyWith(text: controller.text));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
