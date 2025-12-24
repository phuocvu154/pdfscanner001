import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/convert_viewmodel.dart';

class ConvertView extends StatelessWidget {
  const ConvertView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConvertViewModel(),
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
        _convertCard(context, 'DOC to PDF', Icons.description),
        _convertCard(context, 'PNG to PDF', Icons.image),
        _convertCard(context, 'SVG to PDF', Icons.draw),
        _convertCard(context, 'JPG to PDF', Icons.photo),
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
        onTap: () => context.read<ConvertViewModel>().onSelect(title),
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
