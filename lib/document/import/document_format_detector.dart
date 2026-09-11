import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/format_match.dart';

final class DocumentFormatDetector {
  const DocumentFormatDetector();

  Future<FormatMatch> detect(String path) {
    return Isolate.run(() => _detectSync(path));
  }

  static FormatMatch _detectSync(String path) {
    final File file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('Document does not exist.', path);
    }

    final List<int> header = _readHeader(file, 2048);
    final String extension = _extensionOf(path);

    if (_containsAscii(header, '%PDF-')) {
      return const FormatMatch(
        format: DocumentFormat.pdf,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_startsWithAscii(header, 'AT&TFORM')) {
      return const FormatMatch(
        format: DocumentFormat.djvu,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_startsWithBytes(header, const <int>[0x89, 0x50, 0x4E, 0x47])) {
      return const FormatMatch(
        format: DocumentFormat.image,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_startsWithBytes(header, const <int>[0xFF, 0xD8, 0xFF])) {
      return const FormatMatch(
        format: DocumentFormat.image,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_startsWithAscii(header, 'GIF87a') || _startsWithAscii(header, 'GIF89a')) {
      return const FormatMatch(
        format: DocumentFormat.image,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_isWebp(header)) {
      return const FormatMatch(
        format: DocumentFormat.image,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_startsWithAscii(header, r'{\rtf')) {
      return const FormatMatch(
        format: DocumentFormat.rtf,
        confidence: FormatConfidence.exact,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_isRar(header)) {
      if (extension == 'cbr') {
        return const FormatMatch(
          format: DocumentFormat.cbr,
          confidence: FormatConfidence.high,
          evidence: <FormatEvidence>{
            FormatEvidence.signature,
            FormatEvidence.extension,
          },
        );
      }
      return const FormatMatch(
        format: DocumentFormat.unknown,
        confidence: FormatConfidence.medium,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    if (_isMobi(header)) {
      final DocumentFormat format = switch (extension) {
        'azw3' => DocumentFormat.azw3,
        'azw' => DocumentFormat.azw,
        _ => DocumentFormat.mobi,
      };
      return FormatMatch(
        format: format,
        confidence: FormatConfidence.high,
        evidence: <FormatEvidence>{
          FormatEvidence.signature,
          if (extension.isNotEmpty) FormatEvidence.extension,
        },
      );
    }

    if (_isZip(header)) {
      return _inspectZip(path, extension);
    }

    final String textPrefix = _decodeTextPrefix(header).toLowerCase();
    if (textPrefix.contains('<fictionbook')) {
      return const FormatMatch(
        format: DocumentFormat.fb2,
        confidence: FormatConfidence.high,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }
    if (textPrefix.contains('<html') || textPrefix.contains('<!doctype html')) {
      return const FormatMatch(
        format: DocumentFormat.html,
        confidence: FormatConfidence.high,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    }

    final DocumentFormat extensionFormat = _formatFromExtension(extension);
    return FormatMatch(
      format: extensionFormat,
      confidence: extensionFormat == DocumentFormat.unknown
          ? FormatConfidence.low
          : FormatConfidence.medium,
      evidence: extensionFormat == DocumentFormat.unknown
          ? const <FormatEvidence>{}
          : const <FormatEvidence>{FormatEvidence.extension},
    );
  }

  static FormatMatch _inspectZip(String path, String extension) {
    final InputFileStream input = InputFileStream(path);
    Archive? archive;
    try {
      archive = ZipDecoder().decodeStream(input);
      final Set<String> names = archive.files
          .map((ArchiveFile file) => file.name.replaceAll('\\', '/').toLowerCase())
          .toSet();

      if (names.contains('word/document.xml')) {
        return _containerMatch(DocumentFormat.docx, extension == 'docx');
      }
      if (names.contains('ppt/presentation.xml')) {
        return _containerMatch(DocumentFormat.pptx, extension == 'pptx');
      }
      if (names.contains('xl/workbook.xml')) {
        return _containerMatch(DocumentFormat.xlsx, extension == 'xlsx');
      }
      if (names.contains('meta-inf/container.xml') &&
          names.any((String name) => name.endsWith('.opf'))) {
        return _containerMatch(DocumentFormat.epub, extension == 'epub');
      }

      final bool looksLikeOdf = names.contains('content.xml') &&
          names.contains('meta-inf/manifest.xml');
      if (looksLikeOdf) {
        final DocumentFormat odf = switch (extension) {
          'odt' => DocumentFormat.odt,
          'odp' => DocumentFormat.odp,
          'ods' => DocumentFormat.ods,
          _ => DocumentFormat.unknown,
        };
        if (odf != DocumentFormat.unknown) {
          return _containerMatch(odf, true);
        }
      }

      final int imageEntries = names.where(_isImageName).length;
      final int fileEntries = archive.files.where((ArchiveFile file) => file.isFile).length;
      if (extension == 'cbz' && fileEntries > 0 && imageEntries > 0) {
        return const FormatMatch(
          format: DocumentFormat.cbz,
          confidence: FormatConfidence.high,
          evidence: <FormatEvidence>{
            FormatEvidence.container,
            FormatEvidence.extension,
          },
        );
      }

      final DocumentFormat extensionFormat = _formatFromExtension(extension);
      if (_zipBackedFormats.contains(extensionFormat)) {
        return FormatMatch(
          format: extensionFormat,
          confidence: FormatConfidence.medium,
          evidence: const <FormatEvidence>{
            FormatEvidence.container,
            FormatEvidence.extension,
          },
        );
      }

      return const FormatMatch(
        format: DocumentFormat.unknown,
        confidence: FormatConfidence.low,
        evidence: <FormatEvidence>{FormatEvidence.container},
      );
    } on ArchiveException {
      return const FormatMatch(
        format: DocumentFormat.unknown,
        confidence: FormatConfidence.low,
        evidence: <FormatEvidence>{FormatEvidence.signature},
      );
    } finally {
      input.closeSync();
      archive?.clearSync();
    }
  }

  static FormatMatch _containerMatch(DocumentFormat format, bool extensionAgrees) {
    return FormatMatch(
      format: format,
      confidence: extensionAgrees ? FormatConfidence.exact : FormatConfidence.high,
      evidence: <FormatEvidence>{
        FormatEvidence.container,
        if (extensionAgrees) FormatEvidence.extension,
      },
    );
  }

  static List<int> _readHeader(File file, int maxBytes) {
    final RandomAccessFile handle = file.openSync();
    try {
      final int length = math.min(file.lengthSync(), maxBytes);
      return handle.readSync(length);
    } finally {
      handle.closeSync();
    }
  }

  static bool _startsWithAscii(List<int> bytes, String value) {
    return _startsWithBytes(bytes, ascii.encode(value));
  }

  static bool _startsWithBytes(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (int index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  static bool _containsAscii(List<int> bytes, String value) {
    final List<int> signature = ascii.encode(value);
    if (bytes.length < signature.length) return false;
    for (int start = 0; start <= bytes.length - signature.length; start++) {
      bool matches = true;
      for (int offset = 0; offset < signature.length; offset++) {
        if (bytes[start + offset] != signature[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  static bool _isZip(List<int> bytes) {
    return _startsWithBytes(bytes, const <int>[0x50, 0x4B, 0x03, 0x04]) ||
        _startsWithBytes(bytes, const <int>[0x50, 0x4B, 0x05, 0x06]) ||
        _startsWithBytes(bytes, const <int>[0x50, 0x4B, 0x07, 0x08]);
  }

  static bool _isRar(List<int> bytes) {
    return _startsWithBytes(
          bytes,
          const <int>[0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00],
        ) ||
        _startsWithBytes(
          bytes,
          const <int>[0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00],
        );
  }

  static bool _isWebp(List<int> bytes) {
    if (bytes.length < 12) return false;
    return ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP';
  }

  static bool _isMobi(List<int> bytes) {
    if (bytes.length < 68) return false;
    return ascii.decode(bytes.sublist(60, 68), allowInvalid: true) == 'BOOKMOBI';
  }

  static String _decodeTextPrefix(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true).trimLeft();
  }

  static bool _isImageName(String name) {
    return const <String>{
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.avif',
      '.bmp',
      '.tif',
      '.tiff',
    }.any(name.endsWith);
  }

  static String _extensionOf(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    final int dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static DocumentFormat _formatFromExtension(String extension) {
    return switch (extension) {
      'pdf' => DocumentFormat.pdf,
      'djvu' || 'djv' => DocumentFormat.djvu,
      'epub' || 'kepub' => DocumentFormat.epub,
      'fb2' || 'fbz' => DocumentFormat.fb2,
      'mobi' || 'prc' => DocumentFormat.mobi,
      'azw' => DocumentFormat.azw,
      'azw3' => DocumentFormat.azw3,
      'kfx' => DocumentFormat.kfx,
      'docx' => DocumentFormat.docx,
      'odt' => DocumentFormat.odt,
      'rtf' => DocumentFormat.rtf,
      'pptx' => DocumentFormat.pptx,
      'odp' => DocumentFormat.odp,
      'xlsx' || 'xlsm' => DocumentFormat.xlsx,
      'ods' => DocumentFormat.ods,
      'csv' || 'tsv' => DocumentFormat.csv,
      'md' || 'markdown' || 'mdown' => DocumentFormat.markdown,
      'txt' => DocumentFormat.text,
      'html' || 'htm' || 'xhtml' => DocumentFormat.html,
      'cbz' => DocumentFormat.cbz,
      'cbr' => DocumentFormat.cbr,
      'png' ||
      'jpg' ||
      'jpeg' ||
      'gif' ||
      'webp' ||
      'avif' ||
      'bmp' ||
      'tif' ||
      'tiff' => DocumentFormat.image,
      _ => DocumentFormat.unknown,
    };
  }

  static const Set<DocumentFormat> _zipBackedFormats = <DocumentFormat>{
    DocumentFormat.epub,
    DocumentFormat.docx,
    DocumentFormat.pptx,
    DocumentFormat.xlsx,
    DocumentFormat.odt,
    DocumentFormat.odp,
    DocumentFormat.ods,
    DocumentFormat.cbz,
  };
}
