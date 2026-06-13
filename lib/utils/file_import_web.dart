import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> pickJsonFile() async {
  final completer = Completer<String?>();

  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json'
    ..multiple = false;

  input.onChange.listen((_) {
    if (input.files == null || input.files!.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = input.files![0];
    final reader = html.FileReader();
    reader.onLoad.listen((_) => completer.complete(reader.result as String?));
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsText(file);
  });

  // If the user cancels without selecting, resolve after a short window
  html.document.body?.append(input);
  input.click();
  input.remove();

  return completer.future;
}
