import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../documents/document_repository.dart';
import '../../documents/document_viewmodel.dart';
import '../../home/home_types.dart';
import '../../home/home_viewmodel.dart';
import '../../pdf/pdf_view/pdf_view_screen.dart';
import '../viewmodel/convert_viewmodel.dart';

class ConvertView extends StatelessWidget {
  const ConvertView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConvertViewModel(context.read<DocumentRepository>()),
      child: const _ConvertContent(),
    );
  }
}

class _ConvertContent extends StatelessWidget {
  const _ConvertContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConvertViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _convertCard(context, 'PNG to PDF', Icons.image),
        _convertCard(context, 'JPG to PDF', Icons.photo),
        _convertCard(
          context,
          'SVG to PDF',
          Icons.picture_in_picture_alt_outlined,
        ),
        _convertCard(context, 'DOC to PDF', Icons.description),
        _convertCard(context, 'EXCEL to PDF', Icons.table_chart),
        const SizedBox(height: 12),
        _otherSection(vm),
      ],
    );
  }

  Widget _convertCard(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final doc = await context.read<ConvertViewModel>().onSelect(title);

          if (doc != null && context.mounted) {
            context.read<DocumentsViewModel>().addDocument(doc);

            context.read<HomeViewModel>().changeTab(HomeTab.myFiles);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PdfViewScreen(document: doc)),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otherSection(ConvertViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text(
              'Other...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              vm.expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onTap: vm.toggleExpand,
          ),
          if (vm.expanded)
            ...vm.otherItems.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => vm.onSelect(e),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F2F2),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(e),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
