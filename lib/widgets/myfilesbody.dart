import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/documents/document_item.dart';
import '../features/documents/document_viewmodel.dart';
import '../features/home/home_types.dart';
import '../features/home/home_viewmodel.dart';
import '../features/pdf/pdf_view/pdf_view_screen.dart';


import 'myfiles_widgets.dart';

class MyFilesBody extends StatelessWidget {
  final HomeViewModel vm;

  const MyFilesBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    final docsVm = context.watch<DocumentsViewModel>().documents;

    final recentDocs = _filterRecent(docsVm, vm.filter);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== FOLDERS =====
        ...vm.folders.map(
          (folder) => folderCard(
            context: context,
            folderId: folder['id'],
            title: folder['name'],
            onMore: () {
              showFolderMenu(
                context,
                folderId: folder['id'],
                onRename: () {
                  showRenameFolderDialog(
                    context,
                    folderId: folder['id'],
                    oldName: folder['name'],
                  );
                },
              );
            },
          ),
        ),

        // ===== RECENTLY =====
        if (recentDocs.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Recently',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          recentFilter(vm),
          const SizedBox(height: 12),

          ...recentDocs.map((file) => DocumentRow(file: file)),
        ],
      ],
    );
  }
}

List<DocumentItem> _filterRecent(List<DocumentItem> docs, RecentFilter filter) {
  final now = DateTime.now();

  return docs.where((f) {
    switch (filter) {
      case RecentFilter.lastWeek:
        return f.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      case RecentFilter.lastMonth:
        return f.createdAt.isAfter(now.subtract(const Duration(days: 30)));
      case RecentFilter.lastYear:
        return f.createdAt.isAfter(now.subtract(const Duration(days: 365)));
    }
  }).toList();
}

class DocumentRow extends StatelessWidget {
  final DocumentItem file;

  const DocumentRow({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PdfViewScreen(document: file)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(width: 48, height: 64, color: Colors.grey.shade300),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${file.pageCount} page • ${formatDate(file.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            if (vm.selectionMode)
              Checkbox(
                value: vm.isSelected(file),
                onChanged: (_) => vm.toggleSelect(file),
              )
            else
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showRecentItemMenu(context, file),
              ),
          ],
        ),
      ),
    );
  }
}

void _showRecentItemMenu(BuildContext context, DocumentItem file) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MenuItem(
            'Open',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewScreen(document: file),
                ),
              );
            },
          ),
          MenuItem(
            'Move to folder',
            onTap: () {
              Navigator.pop(context);
              showMoveToFolderDialog(context, document: file);
            },
          ),

          MenuItem(
            'Delete',
            destructive: true,
            onTap: () async {
              Navigator.pop(context);
              await context.read<DocumentsViewModel>().deleteDocument(file.id);
            },
          ),
        ],
      ),
    ),
  );
}
