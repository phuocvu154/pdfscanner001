import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pdf/pdf_preview_view.dart';
import 'document__viewmodel.dart';
import 'document_item.dart';

class DocumentsView extends StatelessWidget {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();

    // load lần đầu
    if (vm.items.isEmpty) {
      // gọi ở build đầu tiên
      Future.microtask(() => vm.loadDocuments());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tài liệu đã quét')),
      body: vm.items.isEmpty
          ? const Center(child: Text('Chưa có tài liệu nào'))
          : ListView.builder(
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final doc = vm.items[index];
                return _documentTile(context, doc, vm);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // đi tới màn scan
          Navigator.pushNamed(context, '/scan');
        },
        child: const Icon(Icons.document_scanner),
      ),
    );
  }

  Widget _documentTile(
    BuildContext context,
    DocumentItem doc,
    DocumentsViewModel vm,
  ) {
    return ListTile(
      title: Text(doc.name),
      subtitle: Text(
        'Trang: ${doc.pageCount} • ${doc.createdAt.toLocal().toString().split(".").first}',
      ),
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => vm.deleteDocument(doc.id),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfPreviewView(path: doc.path)),
        );
      },
    );
  }
}