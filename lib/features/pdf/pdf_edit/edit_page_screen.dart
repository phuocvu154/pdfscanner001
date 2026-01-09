import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit_page_viewmodel.dart';
import 'edit_result.dart';
import 'image_overlay.dart';
import 'signature_editor_screen.dart';
import 'text_overlay.dart';
import 'text_style_editor.dart';
import 'package:image_picker/image_picker.dart';

class EditPageScreen extends StatelessWidget {
  final String imagePath;
  final int pageIndex;
  final List<TextOverlay> initialTexts;
  final List<ImageOverlay> initialImages;

  const EditPageScreen({
    super.key,
    required this.imagePath,
    required this.pageIndex,
    required this.initialTexts,
    required this.initialImages,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPageViewModel(
        imagePath: imagePath,
        initialTexts: initialTexts,
        initialImages: initialImages,
      ),
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

                        // ===== IMAGE OVERLAY LAYER =====
                        ...vm.images.asMap().entries.map((entry) {
                          final i = entry.key;
                          final img = entry.value;

                          final centerX =
                              offsetX +
                              img.relativePosition.dx * renderSize.width;
                          final centerY =
                              offsetY +
                              img.relativePosition.dy * renderSize.height;

                          final sizePx = img.scale * renderSize.width;

                          return Positioned(
                            left: centerX - sizePx / 2,
                            top: centerY - sizePx / 2,
                            child: GestureDetector(
                              onScaleStart: vm.onImageScaleStart(i),
                              onScaleUpdate: (details) {
                                if (details.pointerCount == 1 &&
                                    details.scale == 1.0) {
                                  vm.moveImage(
                                    i,
                                    details.focalPointDelta,
                                    renderSize,
                                  );
                                } else if (details.pointerCount >= 2) {
                                  vm.onImageScaleUpdate(i)(details);
                                }
                              },
                              onLongPress: () => vm.selectImage(i),
                              child: Transform.rotate(
                                angle: img.rotation,
                                child: Image.file(
                                  File(img.imagePath),
                                  width: sizePx,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        }),

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
                              onScaleStart: vm.onScaleStart(i),
                              onScaleUpdate: (details) {
                                if (details.pointerCount == 1 &&
                                    details.scale == 1.0) {
                                  vm.moveText(
                                    i,
                                    details.focalPointDelta,
                                    renderSize,
                                  );
                                } else if (details.pointerCount >= 2) {
                                  vm.onScaleUpdate(i)(details);
                                }
                              },

                              onDoubleTap: () =>
                                  _showEditTextBottomSheet(context, vm, i),
                              child: Builder(
                                builder: (_) {
                                  final fontSizePx =
                                      t.fontScale * renderSize.width;

                                  return Transform.rotate(
                                    angle: t.rotation,
                                    child: Text(
                                      t.text,
                                      style: TextStyle(
                                        fontSize: fontSizePx,
                                        color: t.color,
                                        fontFamily: t.fontFamily,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  );
                                },
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
                          Navigator.pop(
                            context,
                            EditPageResult(
                              texts: vm.texts,
                              images: vm.images, // 🔥 QUAN TRỌNG
                            ),
                          );
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
          _tool(Icons.image, 'Add Image', () {
            _showAddImageSheet(context, vm);
          }),
          _tool(Icons.edit, 'Signature', () async {
            final result = await Navigator.push<SignatureResult>(
              context,
              MaterialPageRoute(builder: (_) => const SignatureEditorScreen()),
            );

            if (result != null) {
              vm.addImage(result.imagePath); // 🔥 DÙNG LẠI IMAGE OVERLAY
            }
          }),
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TextStyleEditor(
      initial: TextOverlay(
        text: '',
        relativePosition: const Offset(0.5, 0.5),
        fontScale: 0.04,
        color: Colors.black,
        fontFamily: 'Roboto',
      ),
      onDone: (newText) {
        vm.addText(
          newText.text,
          newText.relativePosition,
          newText.fontScale,
          color: newText.color,
          fontFamily: newText.fontFamily,
        );
        Navigator.pop(context);
      },
    ),
  );

  // final controller = TextEditingController();

  // showDialog(
  //   context: context,
  //   builder: (_) => AlertDialog(
  //     title: const Text('Add text'),
  //     content: TextField(
  //       controller: controller,
  //       autofocus: true,
  //       decoration: const InputDecoration(hintText: 'Enter text'),
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Navigator.pop(context),
  //         child: const Text('Cancel'),
  //       ),
  //       ElevatedButton(
  //         onPressed: () {
  //           if (controller.text.trim().isEmpty) return;

  //           // ✅ CHUẨN: vị trí tương đối giữa ảnh
  //           vm.addText(controller.text.trim(), const Offset(0.5, 0.5));

  //           Navigator.pop(context);
  //         },
  //         child: const Text('Add'),
  //       ),
  //     ],
  //   ),
  // );
}

// ================= EDIT TEXT =================
void _showEditTextBottomSheet(
  BuildContext context,
  EditPageViewModel vm,
  int index,
) {
  final oldText = vm.texts[index];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TextStyleEditor(
      initial: oldText,
      onDone: (updated) {
        vm.updateText(
          index,
          text: updated.text,
          color: updated.color,
          fontScale: updated.fontScale,
          fontFamily: updated.fontFamily,
        );
        Navigator.pop(context);
      },
      onDelete: () {
        vm.deleteText(index);
        Navigator.pop(context);
      },
    ),
  );
}

// void _showEditTextDialog(
//   BuildContext context,
//   EditPageViewModel vm,
//   int index,
// )
// //   final text = vm.texts[index];
//   final controller = TextEditingController(text: text.text);

//   showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: const Text('Edit text'),
//       content: TextField(controller: controller),
//       actions: [
//         TextButton(
//           onPressed: () {
//             vm.deleteText(index);
//             Navigator.pop(context);
//           },
//           child: const Text('Delete'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             vm.updateText(index, text.copyWith(text: controller.text));
//             Navigator.pop(context);
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     ),
//   );
// }
void _showAddImageSheet(BuildContext context, EditPageViewModel vm) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('From library'),
            onTap: () async {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.gallery);
              if (img != null) vm.addImage(img.path);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Take a photo'),
            onTap: () async {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.camera);
              if (img != null) vm.addImage(img.path);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
