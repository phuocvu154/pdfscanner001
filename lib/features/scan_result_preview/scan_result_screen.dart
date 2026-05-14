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
// ... imports như cũ ...

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
                return _buildPagePreview(context, vm, index);
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
                    await _openEditPage(context);
                  },
                ),
                ActionItem(
                  icon: Icons.more_vert,
                  label: 'Other',
                  onTap: () => _showMoreMenu(context),
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

  // ===== BUILD PAGE PREVIEW =====
  Widget _buildPagePreview(
    BuildContext context,
    DocumentComposeViewModel vm,
    int index,
  ) {
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
            final offsetX = (constraints.maxWidth - renderSize.width) / 2;
            final offsetY = (constraints.maxHeight - renderSize.height) / 2;

            // Trong _buildPagePreview, sau khi tính renderSize:
            debugPrint('📐 PdfView - constraints: ${constraints.biggest}');
            debugPrint('📐 PdfView - renderSize: $renderSize');
            debugPrint('📐 PdfView - offsetX: $offsetX, offsetY: $offsetY');

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

                // ===== IMAGE OVERLAYS =====
                ...vm.imageOverlaysOfPage(index).map((img) {
                  final centerX =
                      offsetX + img.relativePosition.dx * renderSize.width;
                  final centerY =
                      offsetY + img.relativePosition.dy * renderSize.height;
                  final displayWidth = img.scale * renderSize.width;

                  // ✅ Tính đúng height theo naturalSize
                  final naturalSize = img.naturalSize;
                  final displayHeight =
                      (naturalSize != null && naturalSize.width > 0)
                      ? displayWidth * (naturalSize.height / naturalSize.width)
                      : displayWidth;

                  return Positioned(
                    left: centerX - displayWidth / 2,
                    top: centerY - displayHeight / 2, // ✅ dùng displayHeight
                    child: Transform.rotate(
                      angle: img.rotation,
                      child: Image.file(
                        File(img.imagePath),
                        width: displayWidth,
                        height: displayHeight,
                        fit: BoxFit.fill,
                      ),
                    ),
                  );
                }),

                // ===== TEXT OVERLAYS =====
                ...vm.textOverlaysOfPage(index).map((t) {
                  final left =
                      offsetX + t.relativePosition.dx * renderSize.width;
                  final top =
                      offsetY + t.relativePosition.dy * renderSize.height;
                  final fontSize = t.fontScale * renderSize.width;

                  return Positioned(
                    left: left,
                    top: top,
                    child: Transform.rotate(
                      angle: t.rotation,
                      child: Text(
                        t.text,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: t.color,
                          fontFamily: t.fontFamily,
                          backgroundColor: Colors.white.withOpacity(0.6),
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
  }

  // ===== OPEN EDIT PAGE =====
  Future<void> _openEditPage(BuildContext context) async {
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

    // 🔥 Cập nhật ngay khi nhận kết quả
    if (result != null) {
      print(
        '📝 Received edit result: ${result.texts.length} texts, ${result.images.length} images',
      );

      vm.setPageTextOverlays(pageIndex, result.texts);
      vm.setPageImageOverlays(pageIndex, result.images);

      // ✅ Force PageView refresh (optional, nhưng giúp đảm bảo)
      setState(() {});
    }
  }

  void _showMoreMenu(BuildContext context) {
    final vm = context.read<DocumentComposeViewModel>();
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

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature – coming soon')));
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
