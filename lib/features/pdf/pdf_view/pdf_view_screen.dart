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

    if (vm.isLoading || vm.pages.isEmpty) {
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
              await vm.saveWithEdits();
              Navigator.pop(context, true);
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

  return LayoutBuilder(
    builder: (context, constraints) {
      return FutureBuilder<ImageInfo>(
        future: _getImageInfo(Image.file(imageFile)),
        builder: (context, snapshot) {
          // 🔴 SỬA: Giống ScanResultScreen - return SizedBox khi chưa có data
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
                final sizePx = img.scale * renderSize.width;

                return Positioned(
                  left: centerX - sizePx / 2,
                  top: centerY - sizePx / 2,
                  child: Transform.rotate(
                    angle: img.rotation,
                    child: Image.file(
                      File(img.imagePath),
                      width: sizePx,
                      fit: BoxFit.contain,
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
    final vm = context.read<PdfViewViewModel>();
    final pageIndex = vm.currentIndex;

    // 🔴 SỬA: Dùng pageImagePaths[pageIndex] thay vì document.path[pageIndex]
    final result = await Navigator.push<EditPageResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPageScreen(
          imagePath: vm.pageImagePaths[pageIndex], // ✅ ĐÂY LÀ ĐÚNG
          pageIndex: pageIndex,
          initialTexts: vm.textOverlaysOfPage(pageIndex),
          initialImages: vm.imageOverlaysOfPage(pageIndex),
        ),
      ),
    );

    if (result != null) {
      debugPrint(
        '📝 Received edit result: ${result.texts.length} texts, ${result.images.length} images',
      );

      vm.setPageTextOverlays(pageIndex, result.texts);
      vm.setPageImageOverlays(pageIndex, result.images);

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
