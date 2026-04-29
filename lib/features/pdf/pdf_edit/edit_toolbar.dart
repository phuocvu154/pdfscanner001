// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'edit_page_viewmodel.dart';

// class EditToolbar extends StatelessWidget {
//   const EditToolbar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.read<EditPageViewModel>();

//     return Container(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _btn('Add Text', Icons.text_fields, () {
//             final size = MediaQuery.of(context).size;
//             vm.addTextAtCenter(size);
//           }),
//           _btn('Image', Icons.add_photo_alternate, () {}),
//           _btn('Sign', Icons.edit, () {}),
//         ],
//       ),
//     );
//   }

//   Widget _btn(String t, IconData i, VoidCallback onTap) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(icon: Icon(i), onPressed: onTap),
//         Text(t, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
// }
