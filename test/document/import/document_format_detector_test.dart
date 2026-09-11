import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/import/document_format_detector.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/format_match.dart';

void main() {
  late Directory tempDirectory;
  const DocumentFormatDetector detector = DocumentFormatDetector();

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('kola-format-test-');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('PDF signature wins even when the extension is misleading', () async {
    final File file = File('${tempDirectory.path}/document.bin');
    await file.writeAsString('prefix\n%PDF-1.7\n1 0 obj');

    final FormatMatch match = await detector.detect(file.path);

    expect(match.format, DocumentFormat.pdf);
    expect(match.confidence, FormatConfidence.exact);
    expect(match.evidence, contains(FormatEvidence.signature));
  });

  test('DOCX is identified from ZIP container structure', () async {
    final Archive archive = Archive()
      ..add(ArchiveFile.string('[Content_Types].xml', '<Types/>'))
      ..add(ArchiveFile.string('word/document.xml', '<w:document/>'));
    final File file = File('${tempDirectory.path}/office-package.zip');
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive));

    final FormatMatch match = await detector.detect(file.path);

    expect(match.format, DocumentFormat.docx);
    expect(match.confidence, FormatConfidence.high);
    expect(match.evidence, contains(FormatEvidence.container));
  });

  test('EPUB is identified from its container and OPF package', () async {
    final Archive archive = Archive()
      ..add(ArchiveFile.string('META-INF/container.xml', '<container/>'))
      ..add(ArchiveFile.string('OEBPS/content.opf', '<package/>'));
    final File file = File('${tempDirectory.path}/book.epub');
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive));

    final FormatMatch match = await detector.detect(file.path);

    expect(match.format, DocumentFormat.epub);
    expect(match.confidence, FormatConfidence.exact);
    expect(match.evidence, contains(FormatEvidence.container));
    expect(match.evidence, contains(FormatEvidence.extension));
  });

  test('unknown binary content remains unknown', () async {
    final File file = File('${tempDirectory.path}/mystery.bin');
    await file.writeAsBytes(<int>[0, 1, 2, 3, 4, 5]);

    final FormatMatch match = await detector.detect(file.path);

    expect(match.format, DocumentFormat.unknown);
    expect(match.isRecognized, isFalse);
  });
}
