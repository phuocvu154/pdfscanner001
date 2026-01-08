import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../documents/document_repository.dart';

import '../pdf/pdf_edit/edit_page_screen.dart';
import '../pdf/pdf_edit/edit_result.dart';
import '../pdf/pdf_edit/text_overlay.dart';
import 'scan_compose_viewmodel.dart';
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
              final doc = await vm.saveWithEdits();
              Navigator.pop(context, doc); // 🔥 TRẢ DOC NGƯỢC
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
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final imageFile = File(vm.imageUris[index]);

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
                        final offsetX =
                            (constraints.maxWidth - renderSize.width) / 2;
                        final offsetY =
                            (constraints.maxHeight - renderSize.height) / 2;

                        return Stack(
                          children: [
                            // ===== IMAGE BASE =====
                            Positioned(
                              left: offsetX,
                              top: offsetY,
                              width: renderSize.width,
                              height: renderSize.height,
                              child: Image.file(imageFile, fit: BoxFit.contain),
                            ),

                            // ===== IMAGE OVERLAYS (FIXED) =====
                            ...vm.imageOverlaysOfPage(index).map((img) {
                              final left =
                                  offsetX +
                                  img.relativePosition.dx * renderSize.width;
                              final top =
                                  offsetY +
                                  img.relativePosition.dy * renderSize.height;

                              return Positioned(
                                left: left,
                                top: top,
                                child: Transform.rotate(
                                  angle: img.rotation,
                                  child: Transform.scale(
                                    scale: img.scale,
                                    child: Image.file(File(img.imagePath)),
                                  ),
                                ),
                              );
                            }),

                            // ===== TEXT OVERLAYS (FIXED) =====
                            ...vm.textOverlaysOfPage(index).map((t) {
                              final left =
                                  offsetX +
                                  t.relativePosition.dx * renderSize.width;
                              final top =
                                  offsetY +
                                  t.relativePosition.dy * renderSize.height;

                              return Positioned(
                                left: left,
                                top: top,
                                child: Transform.rotate(
                                  angle: t.rotation,
                                  child: Text(
                                    t.text,
                                    style: TextStyle(
                                      fontSize: t.fontScale * renderSize.width,
                                      color: t.color,
                                      fontFamily: t.fontFamily,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
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
                ActionItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () async {
                    final vm = context.read<DocumentComposeViewModel>();
                    final pageIndex = vm.currentIndex;

                    final result = await Navigator.push<EditPageResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPageScreen(
                          imagePath: vm.imageUris[pageIndex],
                          pageIndex: pageIndex,
                          initialTexts: vm.textOverlaysOfPage(pageIndex),
                          initialImages: vm.imageOverlaysOfPage(pageIndex),
                        ),
                      ),
                    );

                    if (result != null) {
                      vm.setPageTextOverlays(pageIndex, result.texts);
                      vm.setPageImageOverlays(
                        pageIndex,
                        result.images,
                      ); // 🔥 FIX
                    }
                  },
                ),

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
}
