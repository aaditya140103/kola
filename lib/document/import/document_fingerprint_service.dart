import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

final class DocumentFingerprint {
  const DocumentFingerprint({
    required this.algorithm,
    required this.hex,
    required this.fileSize,
  });

  final String algorithm;
  final String hex;
  final int fileSize;

  String get stableId => '$algorithm:$hex';
}

final class DocumentFingerprintService {
  const DocumentFingerprintService();

  Future<DocumentFingerprint> fingerprint(String path) {
    return Isolate.run(() async {
      final File file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('Document does not exist.', path);
      }

      final Digest digest = await sha256.bind(file.openRead()).first;
      final int fileSize = await file.length();
      return DocumentFingerprint(
        algorithm: 'sha256',
        hex: digest.toString(),
        fileSize: fileSize,
      );
    });
  }
}
