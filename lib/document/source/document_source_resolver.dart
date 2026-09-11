import 'dart:io';

import 'package:kola/document/model/document_models.dart';

final class DocumentSourceResolver {
  const DocumentSourceResolver();

  Future<String> resolveReadablePath(DocumentSource source) async {
    final String? candidate = switch (source.kind) {
      DocumentSourceKind.managedCopy => source.managedPath ?? _filePath(source.uri),
      DocumentSourceKind.linkedFile => _filePath(source.uri),
    };

    if (candidate == null || candidate.isEmpty) {
      throw DocumentSourceUnavailableException(source.uri);
    }

    final File file = File(candidate);
    if (!await file.exists()) {
      throw DocumentSourceUnavailableException(source.uri, resolvedPath: candidate);
    }
    return file.absolute.path;
  }

  static String? _filePath(Uri uri) {
    if (uri.scheme != 'file') return null;
    return uri.toFilePath();
  }
}

final class DocumentSourceUnavailableException implements Exception {
  const DocumentSourceUnavailableException(this.uri, {this.resolvedPath});

  final Uri uri;
  final String? resolvedPath;

  @override
  String toString() {
    final String path = resolvedPath == null ? '' : ' ($resolvedPath)';
    return 'DocumentSourceUnavailableException: $uri$path';
  }
}
