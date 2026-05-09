// lib/utils/pdf_save_helper_mobile.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PdfSaveHelper {
  /// On Android/iOS/desktop: saves to Downloads folder and returns the path.
  static Future<String?> save(Uint8List bytes, String filename) async {
    Directory? dir;

    if (Platform.isAndroid) {
      // Save to public Downloads so user can find it in Files app
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        // Fallback to app documents directory
        dir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      // iOS: save to app's documents directory (accessible via Files app)
      dir = await getApplicationDocumentsDirectory();
    } else {
      // Windows / macOS / Linux: save to Downloads folder
      final home = Platform.environment['USERPROFILE'] // Windows
          ??
          Platform.environment['HOME']; // macOS/Linux
      if (home != null) {
        dir = Directory('$home/Downloads');
        if (!await dir.exists()) dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    }

    final file = File('${dir!.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Opens the saved PDF with the device's default viewer.
  static Future<void> open(String path) async {
    await OpenFile.open(path);
  }
}
