import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Mobile / desktop: use the image_picker plugin directly.
Future<(XFile?, Uint8List?)> pickImageFromSource(bool isCamera) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 80,
  );
  if (picked == null) return (null, null);
  final bytes = await picked.readAsBytes();
  return (picked, bytes);
}
