import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pdf/pdf_view/pdf_view_screen.dart';
import 'document_viewmodel.dart';
import 'document_item.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  @override
  void initState() {
    super.initState();

    // 🔴 Load đúng lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tài liệu đã quét')),
      body: _buildBody(vm),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/scan');
        },
        child: const Icon(Icons.document_scanner),
      ),
    );
  }

  Widget _buildBody(DocumentsViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.documents.isEmpty) {
      return const Center(child: Text('Chưa có tài liệu nào'));
    }

    return ListView.builder(
      itemCount: vm.documents.length,
      itemBuilder: (context, index) {
        final doc = vm.documents[index];
        return _documentTile(context, doc, vm);
      },
    );
  }

  Widget _documentTile(
    BuildContext context,
    DocumentItem doc,
    DocumentsViewModel vm,
  ) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(doc.name),
      subtitle: Text(
        'Trang: ${doc.pageCount} • '
        '${doc.createdAt.toLocal().toString().split(".").first}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          await vm.deleteDocument(doc.id);
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewScreen(document: doc)),
        );
      },
    );
  }
}
