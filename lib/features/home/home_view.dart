import 'package:flutter/material.dart';
import 'package:pdfscanner001/features/documents/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_item.dart';
import '../../widgets/myfilesbody.dart';
import '../../widgets/scan_menu_overlay.dart';
import '../convert_files/view/convert_view.dart';
import '../documents/document_item.dart';
import '../scan_result_preview/scan_result_screen.dart';
import 'home_types.dart';
import 'home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // load tài liệu từ Hive sau khi widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final vmDocs = context.watch<DocumentsViewModel>();

    final isMyFiles = vm.currentTab == HomeTab.myFiles;

    return Scaffold(
      backgroundColor: AppColors.background,
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

        // 🔹 TITLE
        title: const Text(
          'PDF Scanner',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),

        // 🔹 CÁC NÚT PHẢI
        actions: vmDocs.selectionMode
            ? [
                TextButton(
                  onPressed: vmDocs.selectAll,
                  child: const Text('Select all'),
                ),
              ]
            : [
                if (isMyFiles)
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined),
                    onPressed: () => _showCreateFolderDialog(context),
                  ),
                IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
      ),

      // body: AnimatedSwitcher(
      //   duration: const Duration(milliseconds: 250),
      //   child: vm.currentTab == HomeTab.myFiles
      //       ? const _HomeEmptyView()
      //       : const ConvertView(),
      // ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: vm.currentTab == HomeTab.myFiles
            ? MyFilesBody(vm: vm)
            : const ConvertView(),
      ),
      floatingActionButtonLocation: vmDocs.selectionMode
          ? null
          : FloatingActionButtonLocation.centerDocked,

      floatingActionButton: vmDocs.selectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showScanMenu(context),
              child: const Icon(Icons.qr_code_scanner),
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
          : _buildBottomBar(vm),
    );
  }

  Widget _buildBottomBar(HomeViewModel vm) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavItem(
              icon: Icons.folder_open,
              label: 'My files',
              isSelected: vm.currentTab == HomeTab.myFiles,
              onTap: () => vm.changeTab(HomeTab.myFiles),
            ),
            const SizedBox(width: 48),
            BottomNavItem(
              icon: Icons.swap_horiz,
              label: 'Convert file',
              isSelected: vm.currentTab == HomeTab.convertFiles,
              onTap: () => vm.changeTab(HomeTab.convertFiles),
            ),
          ],
        ),
      ),
    );
  }

  //   void _showScanMenu(BuildContext context) {
  //     final overlay = Overlay.of(context);
  //     late OverlayEntry entry;

  //     entry = OverlayEntry(
  //       builder: (_) => ScanMenuOverlay(
  //         onClose: () {
  //           entry.remove();
  //         },

  //         // 🔴 BẮT BUỘC PHẢI CÓ
  //         onScanCompleted: (doc) {
  //   entry.remove();

  //   if (doc == null) return;

  //   debugPrint('🏠 HOME RECEIVED DOC: ${doc.id}');

  //   // 1️⃣ add vào DocumentsViewModel (optional)
  //   context.read<DocumentsViewModel>().addDocument(doc);

  //   // 2️⃣ 🔥 QUAN TRỌNG: reload HomeViewModel
  //   context.read<HomeViewModel>().loadFiles();

  //   debugPrint(
  //     '📥 HOME RECENT COUNT: ${context.read<HomeViewModel>().recentFiles.length}',
  //   );
  // }

  //       ),
  //     );

  //     overlay.insert(entry);
  //   }
  void _showScanMenu(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => ScanMenuOverlay(
        onClose: () => entry.remove(),
        onScanCompleted: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;

            context.read<DocumentsViewModel>().loadDocuments();

            debugPrint(
              '📥 DOCS COUNT: ${context.read<DocumentsViewModel>().documents.length}',
            );
          });
        },
      ),
    );

    overlay.insert(entry);
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('New folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter the name of the new folder.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "What's up? Bro",
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: controller.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<HomeViewModel>().createFolder(
                  controller.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
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
}
