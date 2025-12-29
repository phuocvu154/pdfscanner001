import 'package:flutter/foundation.dart';
import 'document_item.dart';
import 'document_repository.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentRepository repo;

  DocumentsViewModel(this.repo);

  // ===== STATE =====
  final List<DocumentItem> _documents = [];
  final Set<String> _selectedIds = {};

  bool _selectionMode = false;
  bool _isLoading = false;
  String _query = '';

  // ===== GETTERS =====
  bool get selectionMode => _selectionMode;
  bool get isLoading => _isLoading;
  Set<String> get selectedIds => _selectedIds;

  List<DocumentItem> get documents {
    if (_query.isEmpty) return List.unmodifiable(_documents);

    final q = _query.toLowerCase();
    return _documents.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  // ===== LOAD =====
  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    _documents
      ..clear()
      ..addAll(repo.getDocuments());

    _isLoading = false;
    notifyListeners();
  }

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
      ..addAll(documents.map((e) => e.id)); // 🔥 list đang hiển thị
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
    await loadDocuments();
  }

  // ===== CRUD =====
  void addDocument(DocumentItem doc) {
    _documents.insert(0, doc);
    debugPrint('📄 ADD DOC: ${doc.name}');
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    repo.deleteDocument(id);
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> moveDocumentToFolder(String documentId, String folderId) async {
    await repo.moveToFolder(documentId: documentId, folderId: folderId);
    notifyListeners();
  }

  // ===== SEARCH =====
  void search(String query) {
    _query = query;
    notifyListeners();
  }
}
