import 'package:flutter/material.dart';
import '../../widgets/scan_menu_overlay.dart';
import '../scanner/scanner_view.dart';

enum HomeTab { myFiles, convertFiles }

class RecentFile {
  final String name;
  final String date;
  final String info;

  RecentFile({required this.name, required this.date, required this.info});
}

class HomeViewModel extends ChangeNotifier {
  HomeTab _currentTab = HomeTab.myFiles;

  HomeTab get currentTab => _currentTab;

  // giả lập data
  final List<RecentFile> recentFiles = [
    RecentFile(
      name: 'Scan Docly December 11(1).png',
      date: 'December 15, 2025',
      info: '1 page, 68KB',
    ),
    RecentFile(
      name: 'Scan Docly December 11(1).pdf',
      date: 'December 15, 2025',
      info: '1 page, 68KB',
    ),
  ];

  bool get hasRecent => recentFiles.isNotEmpty;

  void changeTab(HomeTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  void onScanPressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => ScanMenuOverlay(onClose: () {}),
    );
  }

  void openScanner(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
  }
}
