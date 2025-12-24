import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'document_item.dart';

class DocumentRepository {
  final Box<DocumentItem> box;
  final _uuid = const Uuid();

  DocumentRepository(this.box);

  List<DocumentItem> getDocuments() {
    final list = box.values.toList();

    // sắp xếp mới nhất lên đầu
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  DocumentItem addDocument({
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

    box.put(doc.id, doc);
    return doc;
  }

  void deleteDocument(String id) {
    box.delete(id);
  }
}
