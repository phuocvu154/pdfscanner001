import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/scan_menu_overlay.dart';
import '../documents/document_viewmodel.dart';
import '../folders/folder_repository.dart';
import 'home_types.dart';

class HomeViewModel extends ChangeNotifier {
  final FolderRepository folderRepo;

  List<Map<String, dynamic>> folders = [];

  HomeTab _currentTab = HomeTab.myFiles;
  HomeTab get currentTab => _currentTab;

  RecentFilter _filter = RecentFilter.lastWeek;
  RecentFilter get filter => _filter;

  HomeViewModel(this.folderRepo) {
    loadFolders();
  }

  void loadFolders() {
    folders = folderRepo.getFolders();
    notifyListeners();
  }

  void changeTab(HomeTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  void changeFilter(RecentFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void onScanPressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ScanMenuOverlay(
          onClose: () => Navigator.of(sheetContext).pop(),

          onScanCompleted: (doc) {
            Navigator.of(sheetContext).pop(); // đảm bảo đóng sheet

            if (doc != null) {
              debugPrint('📥 ADD DOC TO DOCUMENTS VM');

              context.read<DocumentsViewModel>().addDocument(doc);

              debugPrint(
                '📥 DOCS COUNT: ${context.read<DocumentsViewModel>().documents.length}',
              );
            }
          },
        );
      },
    );
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    await folderRepo.addFolder(name.trim());
    loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    await folderRepo.deleteFolder(id);
    loadFolders();
  }

  Future<void> renameFolder(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    await folderRepo.renameFolder(id: id, newName: newName.trim());
    loadFolders();
  }
}
