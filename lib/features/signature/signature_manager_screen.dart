import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



import 'signature_model.dart';
import 'signature_repository.dart';

class SignatureManagerScreen extends StatelessWidget {
  final void Function(String imagePath) onSelect;

  const SignatureManagerScreen({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SignatureRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Signatures')),
      body: ListView.builder(
        itemCount: repo.items.length,
        itemBuilder: (_, i) {
          final sig = repo.items[i];

          return ListTile(
            leading: Image.file(File(sig.imagePath), height: 40),
            title: Text(sig.name),
            subtitle: Text(sig.createdAt.toLocal().toString().split('.').first),
            onTap: () {
              onSelect(sig.imagePath);
              Navigator.pop(context);
            },
            onLongPress: () => _showSignatureMenu(context, repo, sig),
          );
        },
      ),
    );
  }
}

void _showSignatureMenu(
  BuildContext context,
  SignatureRepository repo,
  SignatureItem sig,
) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _renameDialog(context, repo, sig);
            },
          ),
          ListTile(
            title: const Text('Delete'),
            textColor: Colors.red,
            onTap: () async {
              Navigator.pop(context);
              await repo.delete(sig.id);
            },
          ),
        ],
      ),
    ),
  );
}



void _renameDialog(
  BuildContext context,
  SignatureRepository repo,
  SignatureItem sig,
) {
  final controller = TextEditingController(text: sig.name);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rename signature'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            repo.rename(sig.id, controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
