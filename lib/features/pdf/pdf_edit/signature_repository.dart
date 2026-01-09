import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'signature_item.dart';

class SignatureRepository {
  static const _dirName = 'signatures';

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_dirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<List<SignatureItem>> loadAll() async {
    final dir = await _dir();
    return dir
        .listSync()
        .whereType<File>()
        .map(
          (f) => SignatureItem(
            imagePath: f.path,
            color: const Color(0xFF000000),
            createdAt: f.lastModifiedSync(),
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<String> save(File image) async {
    final dir = await _dir();
    final path =
        '${dir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png';
    await image.copy(path);
    return path;
  }
}
