import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'signature_model.dart';





class SignatureRepository extends ChangeNotifier {
  final List<SignatureItem> _items = [];

  List<SignatureItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    final sigDir = Directory('${dir.path}/signatures');

    if (!sigDir.existsSync()) return;

    for (final f in sigDir.listSync()) {
      if (f.path.endsWith('.png')) {
        _items.add(
          SignatureItem(
            id: f.uri.pathSegments.last,
            imagePath: f.path,
            name: path.basenameWithoutExtension(f.path),
            createdAt: File(f.path).lastModifiedSync(),
          ),
        );
      }
    }

    notifyListeners();
  }

  Future<void> add(String imagePath, {String? name}) async {
    final id = const Uuid().v4();
    final dir = await getApplicationDocumentsDirectory();
    final sigDir = Directory('${dir.path}/signatures');

    if (!sigDir.existsSync()) {
      sigDir.createSync(recursive: true);
    }

    final newPath = '${sigDir.path}/$id.png';
    await File(imagePath).copy(newPath);

    _items.add(
      SignatureItem(
        id: id,
        imagePath: newPath,
        name: name ?? 'Signature',
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void rename(String id, String newName) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;

    _items[i] = _items[i].copyWith(name: newName);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;

    await File(_items[i].imagePath).delete();
    _items.removeAt(i);
    notifyListeners();
  }
}
