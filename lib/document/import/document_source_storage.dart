import 'dart:io';

import 'package:kola/document/import/document_fingerprint_service.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:path_provider/path_provider.dart';

enum DocumentImportMode { managedCopy, linkedFile }

abstract interface class DocumentSourceStorage {
  Future<DocumentSource> prepare({
    required String sourcePath,
    required DocumentFingerprint fingerprint,
    required DocumentImportMode mode,
  });
}

final class LocalDocumentSourceStorage implements DocumentSourceStorage {
  const LocalDocumentSourceStorage();

  @override
  Future<DocumentSource> prepare({
    required String sourcePath,
    required DocumentFingerprint fingerprint,
    required DocumentImportMode mode,
  }) async {
    final Uri originalUri = Uri.file(sourcePath);
    if (mode == DocumentImportMode.linkedFile) {
      return DocumentSource(
        kind: DocumentSourceKind.linkedFile,
        uri: originalUri,
      );
    }

    final File source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Document does not exist.', sourcePath);
    }

    final Directory supportDirectory = await getApplicationSupportDirectory();
    final Directory libraryDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}documents',
    );
    await libraryDirectory.create(recursive: true);

    final String extension = _safeExtension(sourcePath);
    final String suffix = extension.isEmpty ? '' : '.$extension';
    final String destinationPath =
        '${libraryDirectory.path}${Platform.pathSeparator}${fingerprint.hex}$suffix';
    final File destination = File(destinationPath);

    bool needsCopy = !await destination.exists();
    if (!needsCopy) {
      try {
        needsCopy = await destination.length() != fingerprint.fileSize;
      } on FileSystemException {
        needsCopy = true;
      }
    }

    if (needsCopy) {
      final File temporary = File('$destinationPath.importing');
      if (await temporary.exists()) {
        await temporary.delete();
      }
      await source.copy(temporary.path);
      if (await destination.exists()) {
        await destination.delete();
      }
      await temporary.rename(destination.path);
    }

    return DocumentSource(
      kind: DocumentSourceKind.managedCopy,
      uri: originalUri,
      managedPath: destination.path,
    );
  }

  static String _safeExtension(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    final int dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    final String extension = name.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,12}$').hasMatch(extension) ? extension : '';
  }
}
