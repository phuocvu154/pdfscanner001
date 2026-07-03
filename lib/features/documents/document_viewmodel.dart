import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'document_repository.dart';
import 'document_item.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentRepository repo;

  late final Box<DocumentItem> _box;

  List<DocumentItem> documents = [];

  DocumentsViewModel(this.repo) {
    _box = repo.box;

    // 🔥 AUTO SYNC
    _box.listenable().addListener(_onHiveChanged);

    reload();
  }

  // 🔥 LISTENER
  void _onHiveChanged() {
    debugPrint('📦 Hive changed → auto reload');
    documents = repo.getDocuments();
    notifyListeners();
  }

  // ===== LOAD =====
  void loadDocuments() {
    documents
      ..clear()
      ..addAll(repo.getDocuments());
    notifyListeners();
  }

  void reload() {
    documents = repo.getDocuments();
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

    // ❌ KHÔNG cần loadDocuments nữa
  }

  // ===== CRUD =====
  Future<void> addDocument(DocumentItem doc) async {
    await repo.saveFile(doc);
  }

  Future<void> deleteDocument(String id) async {
    await repo.deleteDocument(id);

    // ❌ KHÔNG cần remove thủ công
  }

  Future<void> moveDocumentToFolder(String documentId, String folderId) async {
    await repo.moveToFolder(documentId: documentId, folderId: folderId);

    // ❌ KHÔNG cần loadDocuments
  }

  // ===== SEARCH =====
  void search(String query) {
    _query = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _box.listenable().removeListener(_onHiveChanged);
    super.dispose();
  }
}
