import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../documents/document_item.dart';
import '../../documents/document_repository.dart';
import '../../scan_result_preview/action_item.dart';

import '../pdf_edit/edit_page_screen.dart';
import '../pdf_edit/edit_result.dart';
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

class _PdfViewBody extends StatefulWidget {
  const _PdfViewBody();

  @override
  State<_PdfViewBody> createState() => _PdfViewBodyState();
}

class _PdfViewBodyState extends State<_PdfViewBody> {
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
    final vm = context.watch<PdfViewViewModel>();

    if (vm.isLoading || vm.pageImagePaths.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(vm.document.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              final vm = context.read<PdfViewViewModel>();

              debugPrint(
                '✅ DONE PDF VIEW: page=${vm.currentIndex}, '
                'texts=${vm.textOverlaysOfPage(vm.currentIndex).length}, '
                'images=${vm.imageOverlaysOfPage(vm.currentIndex).length}',
              );

              await vm.saveWithEdits();

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
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

          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${vm.currentIndex + 1}/${vm.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

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
                  onTap: () => _openEditPage(context),
                ),
                ActionItem(
                  icon: Icons.more_vert,
                  label: 'Other',
                  onTap: () => _showMoreMenu(context),
                ),
              ],
            ),
          ),

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

  // ===== BUILD PAGE PREVIEW =====
  Widget _buildPagePreview(
    BuildContext context,
    PdfViewViewModel vm,
    int index,
  ) {
    if (vm.pageImagePaths.isEmpty || index >= vm.pageImagePaths.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final imagePath = vm.pageImagePaths[index];
    final imageFile = File(imagePath);

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<ImageInfo>(
            future: _getImageInfo(Image.file(imageFile)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final imgW = snapshot.data!.image.width.toDouble();
              final imgH = snapshot.data!.image.height.toDouble();
              final imgRatio = imgW / imgH;

              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              // ✅ Tính renderSize fit màn hình, không padding thừa
              double renderW, renderH;
              if (screenW / screenH < imgRatio) {
                // Màn hình hẹp hơn ảnh → fit theo chiều ngang
                renderW = screenW;
                renderH = screenW / imgRatio;
              } else {
                // Màn hình rộng hơn ảnh → fit theo chiều dọc
                renderH = screenH;
                renderW = screenH * imgRatio;
              }

              final offsetX = (screenW - renderW) / 2;
              final offsetY = (screenH - renderH) / 2;

              debugPrint('🖼️ imgW: $imgW, imgH: $imgH, ratio: $imgRatio');
              debugPrint('📱 screenW: $screenW, screenH: $screenH');
              debugPrint('📐 renderW: $renderW, renderH: $renderH');
              debugPrint('📌 offsetX: $offsetX, offsetY: $offsetY');

              return Stack(
                children: [
                  // BASE IMAGE
                  Positioned(
                    left: offsetX,
                    top: offsetY,
                    width: renderW,
                    height: renderH,
                    child: Image.file(imageFile, fit: BoxFit.fill),
                  ),

                  // IMAGE OVERLAYS
                  ...vm.imageOverlaysOfPage(index).map((img) {
                    final centerX = offsetX + img.relativePosition.dx * renderW;
                    final centerY = offsetY + img.relativePosition.dy * renderH;
                    final displayWidth = img.scale * renderW;
                    final naturalSize = img.naturalSize;
                    final displayHeight =
                        (naturalSize != null && naturalSize.width > 0)
                        ? displayWidth *
                              (naturalSize.height / naturalSize.width)
                        : displayWidth;

                    return Positioned(
                      left: centerX - displayWidth / 2,
                      top: centerY - displayHeight / 2,
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

                  // TEXT OVERLAYS
                  ...vm.textOverlaysOfPage(index).map((t) {
                    final left = offsetX + t.relativePosition.dx * renderW;
                    final top = offsetY + t.relativePosition.dy * renderH;
                    final fontSize = t.fontScale * renderW;

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
      ),
    );
  }

  // ===== OPEN EDIT PAGE =====
  Future<void> _openEditPage(BuildContext context) async {
    final vm = context.read<PdfViewViewModel>();
    final pageIndex = vm.currentIndex;

    final result = await Navigator.push<EditPageResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPageScreen(
          imagePath: vm.pageImagePaths[pageIndex],
          pageIndex: pageIndex,
          initialTexts: vm.textOverlaysOfPage(pageIndex),
          initialImages: vm.imageOverlaysOfPage(pageIndex),
        ),
      ),
    );

    if (result != null) {
      vm.setPageTextOverlays(pageIndex, result.texts);
      vm.setPageImageOverlays(pageIndex, result.images); // ← set đúng chưa?

      // ✅ Thêm debug để xác nhận
      debugPrint(
        '📝 texts: ${result.texts.length}, images: ${result.images.length}',
      );
      debugPrint(
        '📝 overlays sau khi set: ${vm.imageOverlaysOfPage(pageIndex).length}',
      );

      setState(() {});
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetItem('Rename', () => _comingSoon(context, 'Rename')),
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
