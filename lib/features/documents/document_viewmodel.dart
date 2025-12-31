import 'package:flutter/foundation.dart';
import 'package:pdfscanner001/features/documents/document_item.dart';
import 'package:pdfscanner001/features/documents/document_repository.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentRepository repo;
  List<DocumentItem> documents = [];

  DocumentsViewModel(this.repo);

  void loadDocuments() {
    documents
      ..clear()
      ..addAll(repo.getDocuments());
    notifyListeners();
  }

  // ===== STATE =====
  final Set<String> _selectedIds = {};

  bool _selectionMode = false;
  bool _isLoading = false;
  String _query = '';

  // ===== GETTERS =====
  bool get selectionMode => _selectionMode;
  bool get isLoading => _isLoading;
  Set<String> get selectedIds => _selectedIds;

  // ===== SELECTION =====
  void enterSelection(DocumentItem doc) {
    _selectionMode = true;
    _selectedIds.add(doc.id);
    notifyListeners();
  }

  void toggleSelect(DocumentItem doc) {
    if (_selectedIds.contains(doc.id)) {
      _selectedIds.remove(doc.id);
    } else {
      _selectedIds.add(doc.id);
    }

    if (_selectedIds.isEmpty) {
      _selectionMode = false;
    }

    notifyListeners();
  }

  void selectAll() {
    _selectionMode = true;
    _selectedIds
      ..clear()
      ..addAll(documents.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  bool isSelected(DocumentItem doc) => _selectedIds.contains(doc.id);

  // ===== MOVE =====
  Future<void> moveSelectedToFolder(String folderId) async {
    for (final id in _selectedIds) {
      await repo.moveToFolder(documentId: id, folderId: folderId);
    }
    clearSelection();
    loadDocuments();
  }

  // ===== CRUD =====
  void addDocument(DocumentItem doc) {
    documents.insert(0, doc);
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    await repo.deleteDocument(id);
    documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> moveDocumentToFolder(String documentId, String folderId) async {
    await repo.moveToFolder(documentId: documentId, folderId: folderId);

    // 🔥 Cập nhật lại list sau khi move
    loadDocuments();
  }

  // ===== SEARCH =====
  void search(String query) {
    _query = query;
    notifyListeners();
  }
}
