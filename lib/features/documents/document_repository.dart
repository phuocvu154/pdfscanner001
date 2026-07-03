import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'document_item.dart';

class DocumentRepository {
  final Box<DocumentItem> box;

  final _uuid = const Uuid();

  DocumentRepository(this.box);

  Future<void> saveFile(DocumentItem doc) async {
    await box.put(doc.id, doc);
  }

  // ===== GET =====
  List<DocumentItem> getDocuments() {
    final docs = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return docs;
  }

  List<DocumentItem> getDocumentsByFolder(String folderId) {
    final docs = box.values.where((d) => d.folderId == folderId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return docs;
  }

  // ===== CREATE =====
  DocumentItem createDocument({
    required String pdfPath,
    required int pageCount,
    required String name,
  }) {
    final doc = DocumentItem(
      id: const Uuid().v4(),
      name: name,
      path: pdfPath,
      createdAt: DateTime.now(),
      pageCount: pageCount,
    );

    box.put(doc.id, doc); // 🔴 SOURCE OF TRUTH
    return doc;
  }

  // ===== DELETE =====
  Future<void> deleteDocument(String id) async {
    debugPrint("id delete: $id");
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

  // ===== UPDATE =====
  Future<void> updateDocument(DocumentItem updated) async {
    await box.put(updated.id, updated);
  }
}
