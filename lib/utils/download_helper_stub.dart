import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> downloadFileLocally(Uint8List bytes, String filename) async {
  Directory? dir;

  if (Platform.isAndroid) {
    // Try the Downloads folder first (works without permission on Android < 10)
    final dl = Directory('/storage/emulated/0/Download');
    if (await dl.exists()) {
      try {
        final file = File('${dl.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (_) {
        // Android 10+ scoped storage blocks this — fall through
      }
    }
    // Fallback: app-specific external storage (no permission needed)
    dir = await getExternalStorageDirectory();
  } else {
    // getDownloadsDirectory works on macOS/Windows/Linux; returns null on iOS
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
  }

  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
