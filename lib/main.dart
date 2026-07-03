import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfscanner001/features/home/home_viewmodel.dart';

import 'package:provider/provider.dart';

import 'features/documents/document_viewmodel.dart';
import 'features/documents/document_item.dart';
import 'features/documents/document_repository.dart';
import 'features/folders/folder_repository.dart';
import 'features/home/home_view.dart';

import 'features/pdf/pdf_view/pdf_view_screen.dart';

import 'features/scan_result_preview/scan_compose_viewmodel.dart';
import 'features/signature/signature_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(DocumentItemAdapter());

  final docsBox = await Hive.openBox<DocumentItem>('documents_box');
  final foldersBox = await Hive.openBox('folders');

  final documentRepo = DocumentRepository(docsBox);
  final folderRepo = FolderRepository(foldersBox);

  runApp(MyApp(documentRepo: documentRepo, folderRepo: folderRepo));
}

class MyApp extends StatelessWidget {
  final DocumentRepository documentRepo;
  final FolderRepository folderRepo;

  const MyApp({
    super.key,
    required this.documentRepo,
    required this.folderRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ===== REPOSITORIES =====
        Provider<DocumentRepository>.value(value: documentRepo),
        Provider<FolderRepository>.value(value: folderRepo),

        // ===== VIEW MODELS =====
        ChangeNotifierProvider(create: (_) => HomeViewModel(folderRepo)),
        ChangeNotifierProvider(create: (_) => DocumentsViewModel(documentRepo)),

        ChangeNotifierProvider(
          create: (_) => DocumentComposeViewModel([], documentRepo),
        ),

        // ChangeNotifierProvider(create: (_) => ScanViewModel()),
        // ChangeNotifierProvider(
        //   create: (_) => PdfViewModel(PdfRepository(), documentRepo),
        // ),
        // ChangeNotifierProvider(
        //   create: (_) => SignatureRepository()..load(),
        // ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PDF Scanner Demo',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const HomeView(),
        routes: {
          '/pdfPreview': (context) {
            final docItem =
                ModalRoute.of(context)!.settings.arguments as DocumentItem;
            return PdfViewScreen(document: docItem);
          },
        },
      ),
    );
  }
}
