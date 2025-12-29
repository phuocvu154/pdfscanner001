import 'package:flutter/material.dart';

import '../documents/document_item.dart';
import '../documents/document_repository.dart';

class FolderDetailViewModel extends ChangeNotifier {
  final DocumentRepository repo;
  final String folderId;

  FolderDetailViewModel({
    required this.repo,
    required this.folderId,
  }) {
    load();
  }

  List<DocumentItem> documents = [];

  void load() {
    documents = repo.getDocumentsByFolder(folderId);
    notifyListeners();
  }

  Future<void> deleteDocument(
    BuildContext context,
    String documentId,
  ) async {
    repo.deleteDocument(documentId);
    load();
  }
}
