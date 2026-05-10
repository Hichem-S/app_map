import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

Future<(XFile?, Uint8List?)> pickImageFromSource(bool isCamera) async {
  debugPrint('[PICK] starting picker isCamera=$isCamera');
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
  );
  if (picked == null) {
    debugPrint('[PICK] user cancelled or picker returned null');
    return (null, null);
  }
  debugPrint('[PICK] picked path=${picked.path} name=${picked.name} mimeType=${picked.mimeType}');
  final bytes = await picked.readAsBytes();
  debugPrint('[PICK] bytes read: ${bytes.length} bytes');
  return (picked, bytes);
}
