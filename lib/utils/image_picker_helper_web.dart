import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Web: create a hidden <input type="file"> and trigger a programmatic click.
/// On mobile-web the "capture" attribute opens the camera app;
/// on desktop-web it opens the OS file-picker (best possible behaviour).
Future<(XFile?, Uint8List?)> pickImageFromSource(bool isCamera) async {
  final completer = Completer<Uint8List?>();
  String? pickedName;

  final input = html.InputElement(type: 'file')
    ..accept = 'image/*'
    ..style.display = 'none';

  if (isCamera) input.setAttribute('capture', 'environment');

  html.document.body?.append(input);

  late final StreamSubscription changeSub;
  changeSub = input.onChange.listen((_) {
    changeSub.cancel();
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    pickedName = file.name;
    final reader = html.FileReader()..readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  input.click();

  // Timeout so the UI doesn't freeze if the user dismisses the file dialog
  final bytes = await completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () => null,
  );
  input.remove();

  if (bytes == null) return (null, null);

  final name = pickedName ?? 'photo.jpg';
  final ext = name.split('.').last.toLowerCase();
  final mime = ext == 'png' ? 'image/png'
      : ext == 'webp' ? 'image/webp'
      : 'image/jpeg';
  final xfile = XFile.fromData(bytes, name: name, mimeType: mime);
  return (xfile, bytes);
}
