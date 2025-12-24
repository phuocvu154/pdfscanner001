import 'package:hive/hive.dart';

class DocumentItem {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int pageCount;

  DocumentItem({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.pageCount,
  });
}

/// Adapter để Hive biết cách đọc/ghi DocumentItem
class DocumentItemAdapter extends TypeAdapter<DocumentItem> {
  @override
  final int typeId = 1; // đảm bảo số này unique trong app

  @override
  DocumentItem read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final path = reader.readString();
    final createdAtMillis = reader.readInt();
    final pageCount = reader.readInt();

    return DocumentItem(
      id: id,
      name: name,
      path: path,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      pageCount: pageCount,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.path);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.pageCount);
  }
}
