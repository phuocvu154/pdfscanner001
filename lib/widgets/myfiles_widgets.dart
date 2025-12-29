import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/documents/document_item.dart';
import '../features/documents/document_viewmodel.dart';
import '../features/folders/folder_detail_view.dart';
import '../features/home/home_types.dart';
import '../features/home/home_viewmodel.dart';

// ================= DATE =================
String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// ================= FILTER =================
Widget recentFilter(HomeViewModel vm) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        _filterItem(
          label: 'Last week',
          selected: vm.filter == RecentFilter.lastWeek,
          onTap: () => vm.changeFilter(RecentFilter.lastWeek),
        ),
        _filterItem(
          label: 'Last month',
          selected: vm.filter == RecentFilter.lastMonth,
          onTap: () => vm.changeFilter(RecentFilter.lastMonth),
        ),
        _filterItem(
          label: 'Last year',
          selected: vm.filter == RecentFilter.lastYear,
          onTap: () => vm.changeFilter(RecentFilter.lastYear),
        ),
      ],
    ),
  );
}

Widget _filterItem({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    ),
  );
}

// ================= FOLDER CARD =================
Widget folderCard({
  required BuildContext context,
  required String folderId,
  required String title,
  VoidCallback? onMore,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FolderDetailView(folderId: folderId, folderName: title),
        ),
      );
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
          const Icon(Icons.folder),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: onMore),
        ],
      ),
    ),
  );
}

// ================= MENU ITEM =================
class MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const MenuItem(
    this.title, {
    super.key,
    required this.onTap,
    this.destructive = false,
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
            color: destructive
                ? const Color(0xFFFFEAEA)
                : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: destructive ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ================= FOLDER MENU =================
void showFolderMenu(
  BuildContext context, {
  required String folderId,
  VoidCallback? onRename,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuItem(
              'Rename',
              onTap: () {
                Navigator.pop(context);
                onRename?.call();
              },
            ),
            MenuItem(
              'Delete',
              destructive: true,
              onTap: () async {
                Navigator.pop(context);

                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete folder'),
                    content: const Text(
                      'Are you sure you want to delete this folder?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  await context.read<HomeViewModel>().deleteFolder(folderId);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// ================= RENAME DIALOG =================
void showRenameFolderDialog(
  BuildContext context, {
  required String folderId,
  required String oldName,
}) {
  final controller = TextEditingController(text: oldName);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rename folder'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await context.read<HomeViewModel>().renameFolder(
              folderId,
              controller.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

void showMoveToFolderDialog(
  BuildContext context, {
  required DocumentItem document,
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
          children: [
            const Text(
              'Move to folder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (folders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No folders available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            ...folders.map(
              (f) => ListTile(
                leading: const Icon(Icons.folder),
                title: Text(f['name']),
                onTap: () async {
                  await context.read<DocumentsViewModel>().moveDocumentToFolder(
                    document.id,
                    f['id'],
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
