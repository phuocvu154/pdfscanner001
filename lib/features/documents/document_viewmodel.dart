import 'package:flutter/foundation.dart';
import 'package:pdfscanner001/features/documents/document_item.dart';
import 'package:pdfscanner001/features/documents/document_repository.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DocumentRepository repo;
  List<DocumentItem> documents = [];

  DocumentsViewModel(this.repo);

  void loadDocuments() {
    // 🔥 Tạo list mới có thể thay đổi được
    documents = repo.getDocuments();
    debugPrint('📥 DOCS COUNT = ${documents.length}');
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
    debugPrint('📄 ADD DOC: ${doc.name}');
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    // 1️⃣ Xóa khỏi repository
    await repo.deleteDocument(id);

    // 2️⃣ Xóa khỏi list local NGAY LẬP TỨC
    documents.removeWhere((d) => d.id == id);

    // 3️⃣ Xóa khỏi selection nếu đang được chọn
    _selectedIds.remove(id);

    // 4️⃣ Thoát selection mode nếu không còn item nào được chọn
    if (_selectedIds.isEmpty && _selectionMode) {
      _selectionMode = false;
    }

    // 5️⃣ Notify listeners để UI cập nhật
    notifyListeners();

    debugPrint('🗑️ DELETE DOC: $id | COUNT=${documents.length}');
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
