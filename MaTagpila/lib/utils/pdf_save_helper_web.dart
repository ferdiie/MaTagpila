// lib/utils/pdf_save_helper_web.dart
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class PdfSaveHelper {
  /// On web: triggers a browser file download. Returns null (no local path).
  static Future<String?> save(Uint8List bytes, String filename) async {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.setAttribute('download', filename);
    anchor.click();
    web.URL.revokeObjectURL(url);
    return null; // no local path on web
  }

  /// Not applicable on web — PDF was already downloaded via browser.
  static Future<void> open(String path) async {}
}
