import 'text_overlay.dart';
import 'image_overlay.dart';

class EditPageResult {
  final List<TextOverlay> texts;
  final List<ImageOverlay> images;

  const EditPageResult({
    required this.texts,
    required this.images,
  });
}
