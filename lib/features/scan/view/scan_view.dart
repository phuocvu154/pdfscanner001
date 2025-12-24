import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pdf/pdf_viewmodel.dart';
import '../viewmodel/scan_viewmodel.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Test MLKit Document Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: vm.isScanning
                  ? null
                  : () async {
                      await vm.scan();
                    },
              icon: const Icon(Icons.document_scanner),
              label: Text(vm.isScanning ? 'Đang quét...' : 'Quét tài liệu'),
            ),
            const SizedBox(height: 16),

            if (vm.error != null)
              Text(
                'Lỗi: ${vm.error}',
                style: const TextStyle(color: Colors.red),
              ),

            if (vm.lastDocument != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Số trang: ${vm.lastDocument!.imagePaths.length}'),
                  Text(vm.lastDocument!.hasPdf ? 'Có PDF' : 'Chỉ ảnh'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.lastDocument!.imagePaths.length,
                  itemBuilder: (context, index) {
                    final path = vm.lastDocument!.imagePaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: vm.isScanning
                          ? null
                          : () async {
                              final pdfVm = context.read<PdfViewModel>();
                              await pdfVm.generateAndSavePdf(
                                vm.lastDocument!.imagePaths,
                                context,
                              );
                            },
                      child: const Text('Tạo PDF & Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
