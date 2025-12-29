import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'document_item.dart';

class DocumentRepository {
  final Box<DocumentItem> box;

  final _uuid = const Uuid();

  DocumentRepository(this.box);

  // ===== GET =====
  List<DocumentItem> getDocuments() {
    final docs = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(docs);
  }

  List<DocumentItem> getDocumentsByFolder(String folderId) {
    final docs = box.values.where((d) => d.folderId == folderId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(docs);
  }

  // ===== CREATE =====
  DocumentItem createDocument({
    required String pdfPath,
    required int pageCount,
    String? name,
  }) {
    final doc = DocumentItem(
      id: _uuid.v4(),
      name: name ?? 'Scan ${DateTime.now().toIso8601String()}',
      path: pdfPath,
      createdAt: DateTime.now(),
      pageCount: pageCount,
    );

    box.put(doc.id, doc); // 🔴 KEY = id
    return doc;
  }

  // ===== DELETE =====
  Future<void> deleteDocument(String id) async {
    await box.delete(id);
  }

  // ===== MOVE =====
  Future<void> moveToFolder({
    required String documentId,
    required String folderId,
  }) async {
    final old = box.get(documentId);
    if (old == null) return;

    final updated = old.copyWith(folderId: folderId);
    await box.put(documentId, updated);
  }
}
