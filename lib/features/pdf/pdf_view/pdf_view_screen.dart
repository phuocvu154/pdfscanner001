
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../documents/document_item.dart';
import '../../scan_result_preview/action_item.dart';
import 'pdf_view_viewmodel.dart';

class PdfViewScreen extends StatelessWidget {
  final DocumentItem document;

  const PdfViewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PdfViewViewModel(document),
      child: const _PdfViewBody(),
    );
  }
}

class _PdfViewBody extends StatelessWidget {
  const _PdfViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PdfViewViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextButton(
          onPressed: vm.isAddingPage ? null : vm.addPage,
          child: const Text('Add page'),
        ),
        actions: [
          TextButton(
            onPressed: () => vm.onDone(context),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== PREVIEW =====
          Expanded(
            child: PageView.builder(
              itemCount: vm.total,
              onPageChanged: vm.onPageChanged,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.memory(vm.pages[index], fit: BoxFit.contain),
                );
              },
            ),
          ),

          // ===== PAGE INDICATOR =====
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${vm.currentIndex + 1}/${vm.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // ===== ACTION BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionItem(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: vm.deleteCurrent,
                ),
                ActionItem(
                  icon: Icons.folder_open,
                  label: 'Organize file',
                  onTap: () {},
                ),
                ActionItem(icon: Icons.edit, label: 'Edit', onTap: () {}),
                ActionItem(
                  icon: Icons.more_vert,
                  label: 'Other',
                  onTap: () => _showMoreMenu(context, vm),
                ),
              ],
            ),
          ),

          // ===== SHARE =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: vm.share,
                child: const Text('Share'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, PdfViewViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetItem('Combine', vm.combine),
          SheetItem('Split', vm.split),
          SheetItem('Bookmark', vm.bookmark),
          SheetItem('Rename', vm.rename),
          SheetItem('Set Password', vm.setPassword),
          SheetItem('Unset Password', vm.unsetPassword),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
