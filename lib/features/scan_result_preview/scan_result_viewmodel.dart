import 'dart:io';
import 'package:flutter/material.dart';

import '../scanner/document_scanner_service.dart';

class ScanResultViewModel extends ChangeNotifier {
  final DocumentScannerService _scannerService;

  final List<String> _imageUris;
  int _currentIndex = 0;
  bool _isAddingPage = false;

  ScanResultViewModel(
    this._imageUris,
    this._scannerService,
  );

  List<String> get imageUris => List.unmodifiable(_imageUris);
  int get currentIndex => _currentIndex;
  int get total => _imageUris.length;
  bool get isAddingPage => _isAddingPage;

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void deleteCurrent() {
    _imageUris.removeAt(_currentIndex);
    if (_currentIndex >= _imageUris.length) {
      _currentIndex = _imageUris.length - 1;
    }
    notifyListeners();
  }

  /// 🟢 ADD PAGE = quét thêm trang
  Future<void> addPage() async {
    if (_isAddingPage) return;

    _isAddingPage = true;
    notifyListeners();

    try {
      final newImages = await _scannerService.scan();

      if (newImages.isNotEmpty) {
        _imageUris.addAll(newImages);
        _currentIndex = _imageUris.length - 1;
      }
    } catch (e) {
      debugPrint('Add page error: $e');
    } finally {
      _isAddingPage = false;
      notifyListeners();
    }
  }

  /// 🟢 DONE = kết thúc flow
  void done(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  


  void share() {
    // TODO: gắn share_plus
  }

  void combine() {}
  void split() {}
  void bookmark() {}
  void rename() {}
  void setPassword() {}
  void unsetPassword() {}
}
