import 'package:flutter/material.dart';
import 'package:pdfscanner001/features/home/home_viewmodel.dart';

class MyFilesBody extends StatelessWidget {
  final HomeViewModel vm;

  const MyFilesBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _folderCard(
          icon: Icons.folder,
          title: 'All folders',
          subtitle: 'Empty, 0KB',
        ),
        const SizedBox(height: 12),
        _folderCard(
          icon: Icons.bookmark,
          title: 'Bookmark',
          subtitle: 'Empty, 0KB',
        ),

        // 🔥 CHỈ HIỆN KHI KHÔNG EMPTY
       if (vm.hasRecent) ...[
          const SizedBox(height: 24),
          const Text(
            'Recently',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          ...vm.recentFiles.map((file) {
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(file.name),
              subtitle: Text('${file.pageCount} page • ${file.createdAt}'),
              onTap: () {
                // TODO: open preview PDF
              },
            );
          }),
        ],

      ],
    );
  }
}

Widget _folderCard({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEAF2FF),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const Icon(Icons.more_horiz),
      ],
    ),
  );
}

Widget _recentItem(RecentFile file) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 64,
            color: Colors.grey.shade300,
            child: const Icon(Icons.insert_drive_file, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  file.date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  file.info,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.share, size: 20),
        ],
      ),
    ),
  );
}
