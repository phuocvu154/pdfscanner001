import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../documents/document_item.dart';
import '../documents/document_repository.dart';
import '../documents/document_viewmodel.dart';
import '../home/home_viewmodel.dart';
import 'folder_detail_viewmodel.dart';

class FolderDetailView extends StatelessWidget {
  final String folderId;
  final String folderName;

  const FolderDetailView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FolderDetailViewModel(
        repo: context.read<DocumentRepository>(),
        folderId: folderId,
      ),
      child: const _FolderDetailContent(),
    );
  }
}

class _FolderDetailContent extends StatelessWidget {
  const _FolderDetailContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FolderDetailViewModel>();
    final vmDocs = context.watch<DocumentsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // 🔹 NÚT SETTINGS (TRÁI)
        leading: vmDocs.selectionMode
            ? TextButton(
                onPressed: vmDocs.clearSelection,
                child: const Text('Cancel'),
              )
            : IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  // TODO: mở màn hình Settings
                },
              ),

        title: Text(
          vm.documents.isEmpty
              ? 'Empty folder'
              : '${vm.documents.length} files',
        ),
        // 🔹 CÁC NÚT PHẢI
        actions: [
          if (vmDocs.selectionMode)
            TextButton(
              onPressed: vmDocs.selectAll,
              child: const Text('Select all'),
            ),
        ],
      ),

      body: vm.documents.isEmpty
          ? const Center(
              child: Text(
                'No documents in this folder',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.documents.length,
              itemBuilder: (_, index) {
                final doc = vm.documents[index];
                return _documentItem(context, doc);
              },
            ),
      bottomNavigationBar: vmDocs.selectionMode
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  _showMoveToFolderDialog(
                    context,
                    onFolderSelected: (folderId) {
                      vmDocs.moveSelectedToFolder(folderId);
                    },
                  );
                },
                child: const Text('Move'),
              ),
            )
          : null,
    );
  }
}

Widget _documentItem(BuildContext context, DocumentItem file) {
  final vm = context.watch<DocumentsViewModel>();

  return GestureDetector(
    onLongPress: () {
      if (!vm.selectionMode) {
        vm.enterSelection(file);
      }
    },
    onTap: () {
      if (vm.selectionMode) {
        vm.toggleSelect(file);
      } else {
        // TODO: open document
      }
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // thumbnail
          Container(width: 48, height: 64, color: Colors.grey.shade300),
          const SizedBox(width: 12),

          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${file.pageCount} page',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 🔴 CHECKBOX
          if (vm.selectionMode)
            Checkbox(
              value: vm.isSelected(file),
              onChanged: (_) => vm.toggleSelect(file),
            ),
        ],
      ),
    ),
  );
}

void _showMoveToFolderDialog(
  BuildContext context, {
  required Function(String folderId) onFolderSelected,
}) {
  final folders = context.read<HomeViewModel>().folders;

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: folders
              .map(
                (f) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(f['name']),
                  onTap: () {
                    Navigator.pop(context);
                    onFolderSelected(f['id']);
                  },
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

// ignore: unused_element
class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem(
    this.title, {
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDestructive
                ? const Color(0xFFFFEAEA)
                : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
