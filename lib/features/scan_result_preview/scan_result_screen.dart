import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../documents/document_repository.dart';
import '../scanner/document_compose_viewmodel.dart';
import 'action_item.dart';

class ScanResultScreen extends StatelessWidget {
  final List<String> imageUris;

  const ScanResultScreen({super.key, required this.imageUris});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DocumentComposeViewModel(
        imageUris,
        context.read<DocumentRepository>(),
      ),
      child: _ScanResultView(),
    );
  }
}

class _ScanResultView extends StatefulWidget {
  const _ScanResultView();

  @override
  State<_ScanResultView> createState() => _ScanResultViewState();
}

class _ScanResultViewState extends State<_ScanResultView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentComposeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextButton(
          onPressed: vm.isProcessing ? null : vm.addPage,
          child: const Text('Add page'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              debugPrint('🟡 DONE BUTTON PRESSED');

              final vm = context.read<DocumentComposeViewModel>();

              debugPrint('🟡 VM TYPE = ${vm.runtimeType}');

              final doc = await vm.save();

              debugPrint('🟡 AFTER SAVE');

              Navigator.pop(context, doc);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== PREVIEW =====
          Expanded(
            child: PageView.builder(
              controller: _pageController,
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

          // ===== INDICATOR =====
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${vm.currentIndex + 1}/${vm.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // ===== ACTIONS =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionItem(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: vm.total > 1 ? Colors.red : Colors.grey,
                  onTap: () {
                    if (vm.total <= 1) return;

                    vm.deleteCurrent();
                    _pageController.jumpToPage(
                      vm.currentIndex.clamp(0, vm.total - 1),
                    );
                  },
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
                onPressed: () {
                  // TODO: implement share after save
                },
                child: const Text('Share'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature – coming soon')));
  }

  void _showMoreMenu(BuildContext context, DocumentComposeViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetItem('Rename', () => vm.rename(context)),
          SheetItem('Combine', () => _comingSoon(context, 'Combine')),
          SheetItem('Split', () => _comingSoon(context, 'Split')),
          SheetItem('Bookmark', () => _comingSoon(context, 'Bookmark')),
          SheetItem('Set Password', () => _comingSoon(context, 'Set password')),
          SheetItem(
            'Unset Password',
            () => _comingSoon(context, 'Unset password'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
