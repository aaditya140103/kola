import 'dart:io';

import 'package:pdfrx/pdfrx.dart';

/// Flutter tests run from flutter_tester rather than a packaged application.
/// Point PDFium at the native asset Flutter built for this test invocation.
Future<void> initializeTestPdfium() async {
  final name = Platform.isWindows
      ? 'pdfium.dll'
      : Platform.isMacOS
      ? 'libpdfium.dylib'
      : 'libpdfium.so';
  final file = File(
    Platform.environment['PDFIUM_PATH'] ??
        'build/native_assets/${Platform.operatingSystem}/$name',
  );
  if (!file.existsSync()) {
    throw StateError(
      'PDFium test asset is missing: ${file.path}. '
      'Run flutter test with native assets enabled or set PDFIUM_PATH.',
    );
  }
  Pdfrx.pdfiumModulePath = file.absolute.path;
  Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;
  await pdfrxFlutterInitialize();
}
