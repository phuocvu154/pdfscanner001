import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfscanner001/features/home/home_viewmodel.dart';
import 'package:pdfscanner001/features/scanner/document_scanner_service.dart';

import 'package:provider/provider.dart';
import 'features/convert_files/view/convert_view.dart';
import 'features/documents/document_viewmodel.dart';
import 'features/documents/document_item.dart';
import 'features/documents/document_repository.dart';
import 'features/home/home_view.dart';
import 'features/pdf/pdf_preview_view.dart';
import 'features/pdf/pdf_repository.dart';
import 'features/pdf/pdf_viewmodel.dart';
import 'features/scanner/scan_view.dart';
import 'features/scanner/scan_viewmodel.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav_item.dart';
import 'widgets/myfilesbody.dart';
import 'widgets/scan_menu_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentItemAdapter());
  final docsBox = await Hive.openBox<DocumentItem>('documents_box');

  final docRepo = DocumentRepository(docsBox);

  runApp(MyApp(docRepo: docRepo));
}

class MyApp extends StatelessWidget {
  final DocumentRepository docRepo;
  const MyApp({super.key, required this.docRepo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DocumentScannerService()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ScanViewModel()),
        ChangeNotifierProvider(create: (_) => DocumentsViewModel(docRepo)),
        ChangeNotifierProvider(
          create: (_) => PdfViewModel(PdfRepository(), docRepo),
        ),

        // ChangeNotifierProvider(create: (_) => ToolsViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PDF Scanner Demo',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const HomeView(), // <-- dùng HomeView đẹp + gộp Documents
        routes: {
          '/scan': (_) => const ScanView(),
          '/pdfPreview': (context) {
            final path = ModalRoute.of(context)!.settings.arguments as String;
            return PdfPreviewView(path: path);
          },
          // '/tools': (_) => const ToolsView(),
        },
      ),
    );
  }
}
