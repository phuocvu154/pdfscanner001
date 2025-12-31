import 'dart:io';
import 'package:flutter/material.dart' hide EditableText;
import 'package:provider/provider.dart';

import '../../documents/document_item.dart';
import 'edit_page_viewmodel.dart';

class EditPageScreen extends StatelessWidget {
  final DocumentItem document;

  const EditPageScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPageViewModel(document),
      child: const _EditView(),
    );
  }
}

class _EditView extends StatelessWidget {
  const _EditView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditPageViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit – ${vm.document.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: vm.undo),
          IconButton(icon: const Icon(Icons.redo), onPressed: vm.redo),
        ],
      ),
      body: Column(
        children: [
          // ===== PAGE VIEW =====
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // PDF IMAGE (placeholder – sau này thay bằng pdf_render)
                    Positioned.fill(
                      child: Image.file(
                        File(vm.document.path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Text('PDF render here')),
                      ),
                    ),

                    // ===== TEXT LAYER =====
                    ...vm.texts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;

                      return Positioned(
                        left: t.position.dx,
                        top: t.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (d) => vm.moveText(i, d.delta),
                          onDoubleTap: () =>
                              _showEditTextDialog(context, vm, i),
                          child: Text(
                            t.text,
                            style: TextStyle(
                              fontSize: t.fontSize,
                              color: t.color,
                              backgroundColor: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // ===== TOOLBAR =====
          _EditToolbar(),
        ],
      ),
    );
  }
}

class _EditToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditPageViewModel>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tool(
            Icons.text_fields,
            'Add Text',
            () => _showAddTextDialog(context, vm),
          ),
          _tool(Icons.image, 'Image', () {}),
          _tool(Icons.edit, 'Signature', () {}),
        ],
      ),
    );
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
}

// ===== ADD TEXT =====
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
            vm.addText(controller.text, MediaQuery.of(context).size);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ===== EDIT TEXT =====
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
          onPressed: () => vm.deleteText(index),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: () {
            vm.updateText(
              index,
              EditableText(
                text: controller.text,
                position: text.position,
                fontSize: text.fontSize,
                color: text.color,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
