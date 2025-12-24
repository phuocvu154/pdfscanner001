import 'package:flutter/foundation.dart';
import 'document_item.dart';
import 'document_repository.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentRepository repo;

  DocumentsViewModel(this.repo);

  bool isLoading = false;
  List<DocumentItem> _items = [];
  String _query = '';

  List<DocumentItem> get items {
    if (_query.isEmpty) return _items;
    final lower = _query.toLowerCase();
    return _items.where((d) => d.name.toLowerCase().contains(lower)).toList();
  }

  Future<void> loadDocuments() async {
    isLoading = true;
    notifyListeners();
    _items = repo.getDocuments();
    isLoading = false;
    notifyListeners();
  }

  void addDocument(DocumentItem doc) {
    _items.insert(0, doc);
    notifyListeners();
  }

  void deleteDocument(String id) {
    repo.deleteDocument(id);
    _items.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }
}
