enum DocumentFormat {
  pdf,
  djvu,
  epub,
  fb2,
  mobi,
  azw,
  azw3,
  kfx,
  docx,
  odt,
  rtf,
  pptx,
  odp,
  xlsx,
  ods,
  csv,
  markdown,
  text,
  html,
  cbz,
  cbr,
  image,
  unknown,
}

enum DocumentSourceKind { linkedFile, managedCopy }

enum DocumentSupportStatus {
  supported,
  partial,
  unsupported,
  missingSource,
  needsPassword,
  protected,
}

final class DocumentSource {
  const DocumentSource({
    required this.kind,
    required this.uri,
    this.managedPath,
  });

  final DocumentSourceKind kind;
  final Uri uri;
  final String? managedPath;
}

final class DocumentLocation {
  DocumentLocation({
    required this.scheme,
    required Map<String, Object?> data,
    this.label,
  }) : data = Map<String, Object?>.unmodifiable(data);

  final String scheme;
  final Map<String, Object?> data;
  final String? label;
}

final class DocumentMetadata {
  const DocumentMetadata({
    required this.title,
    this.subtitle,
    this.authors = const <String>[],
    this.language,
    this.coverCacheKey,
  });

  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? language;
  final String? coverCacheKey;
}

final class KolaDocument {
  const KolaDocument({
    required this.id,
    required this.source,
    required this.format,
    required this.metadata,
    required this.importedAt,
    required this.updatedAt,
    this.contentHash,
    this.fileSize,
    this.lastOpenedAt,
    this.supportStatus = DocumentSupportStatus.supported,
    this.parserVersion,
    this.revision = 1,
  });

  final String id;
  final String? contentHash;
  final DocumentSource source;
  final DocumentFormat format;
  final DocumentMetadata metadata;
  final int? fileSize;
  final DateTime importedAt;
  final DateTime? lastOpenedAt;
  final DocumentSupportStatus supportStatus;
  final String? parserVersion;
  final int revision;
  final DateTime updatedAt;
}
