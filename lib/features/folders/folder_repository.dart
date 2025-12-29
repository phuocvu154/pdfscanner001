import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class FolderRepository {
  final Box box;
  final _uuid = const Uuid();

  FolderRepository(this.box);

  List<Map<String, dynamic>> getFolders() {
    return box.values
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> addFolder(String name) async {
    await box.add({
      'id': _uuid.v4(),
      'name': name,
      'createdAt': DateTime.now(),
    });
  }

  Future<void> deleteFolder(String id) async {
    final key = box.keys.firstWhere((k) => box.get(k)['id'] == id);
    await box.delete(key);
  }

  Future<void> renameFolder({
    required String id,
    required String newName,
  }) async {
    final key = box.keys.firstWhere((k) => box.get(k)['id'] == id);

    final old = Map<String, dynamic>.from(box.get(key));
    old['name'] = newName;

    await box.put(key, old);
  }
}
