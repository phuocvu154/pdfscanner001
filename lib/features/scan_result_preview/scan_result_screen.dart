import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scanner/document_scanner_service.dart';
import 'scan_result_viewmodel.dart';

class ScanResultScreen extends StatelessWidget {
  final List<String> imageUris;

  const ScanResultScreen({super.key, required this.imageUris});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScanResultViewModel(
        imageUris,
        context.read<DocumentScannerService>(),
      ),
      child: const _ScanResultView(),
    );
  }
}

class _ScanResultView extends StatelessWidget {
  const _ScanResultView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanResultViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextButton(
          onPressed: vm.isAddingPage ? null : vm.addPage,
          child: const Text('Add page'),
        ),
        actions: [
          TextButton(
            onPressed: () => vm.done(context),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Expanded(
            child: PageView.builder(
              itemCount: vm.total,
              onPageChanged: vm.onPageChanged,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.file(
                    File(vm.imageUris[index]),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),

          // Page indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${vm.currentIndex + 1}/${vm.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Bottom actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionItem(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: vm.deleteCurrent,
                ),
                _ActionItem(
                  icon: Icons.folder_open,
                  label: 'Organize file',
                  onTap: () {},
                ),
                _ActionItem(icon: Icons.edit, label: 'Edit', onTap: () {}),
                _ActionItem(
                  icon: Icons.more_vert,
                  label: 'Other',
                  onTap: () => _showMoreMenu(context, vm),
                ),
              ],
            ),
          ),

          // Share button
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

  void _showMoreMenu(BuildContext context, ScanResultViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetItem('Combine', vm.combine),
          _SheetItem('Split', vm.split),
          _SheetItem('Bookmark', vm.bookmark),
          _SheetItem('Rename', vm.rename),
          _SheetItem('Set Password', vm.setPassword),
          _SheetItem('Unset Password', vm.unsetPassword),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SheetItem(this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
