import 'package:flutter/material.dart';

class ConvertViewModel extends ChangeNotifier {
  bool _expanded = false;

  bool get expanded => _expanded;

  final List<String> mainItems = const [
    'DOC to PDF',
    'PNG to PDF',
    'SVG to PDF',
    'JPG to PDF',
  ];

  final List<String> otherItems = const [
    'PNG to PDF',
    'JPG to PDF',
    'SVG to PDF',
    'DOC to PDF',
  ];

  void toggleExpand() {
    _expanded = !_expanded;
    notifyListeners();
  }

  void onSelect(String type) {
    debugPrint('Convert selected: $type');
  }
}
