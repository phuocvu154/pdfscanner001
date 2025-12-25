
import 'package:flutter/material.dart';
import 'package:pdfscanner001/features/documents/document_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_item.dart';
import '../../widgets/myfilesbody.dart';
import '../../widgets/scan_menu_overlay.dart';
import '../convert_files/view/convert_view.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          vm.currentTab == HomeTab.myFiles ? 'PDF Scanner' : 'Convert file',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 12),
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showScanMenu(context),
        child: const Icon(Icons.qr_code_scanner),
      ),

      bottomNavigationBar: _buildBottomBar(vm),
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

  void _showScanMenu(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => ScanMenuOverlay(onClose: () => entry.remove()),
    );

    overlay.insert(entry);
  }
}


