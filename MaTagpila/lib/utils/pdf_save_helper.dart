// lib/utils/pdf_save_helper.dart
//
// Conditional export — Dart picks the right implementation at compile time:
//   • Flutter Web  → pdf_save_helper_web.dart   (dart:html download)
//   • Everything else → pdf_save_helper_mobile.dart (path_provider + open_file)
//
export 'pdf_save_helper_stub.dart'
    if (dart.library.html) 'pdf_save_helper_web.dart'
    if (dart.library.io) 'pdf_save_helper_mobile.dart';
