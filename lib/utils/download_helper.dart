/// Cross-platform QR download:
///   Web  → dart:html Blob → triggers browser "Save As" dialog
///   Mobile / Desktop → path_provider Downloads folder

export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
