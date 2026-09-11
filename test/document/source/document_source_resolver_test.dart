import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/source/document_source_resolver.dart';

void main() {
  const DocumentSourceResolver resolver = DocumentSourceResolver();

  test('managed copy resolves managed path', () async {
    final Directory temp = await Directory.systemTemp.createTemp('kola-source-');
    addTearDown(() => temp.delete(recursive: true));
    final File managed = File('${temp.path}/managed.pdf');
    await managed.writeAsBytes(<int>[1, 2, 3]);

    final String path = await resolver.resolveReadablePath(
      DocumentSource(
        kind: DocumentSourceKind.managedCopy,
        uri: Uri.file('/original/book.pdf'),
        managedPath: managed.path,
      ),
    );

    expect(path, managed.absolute.path);
  });

  test('linked file resolves its file uri', () async {
    final Directory temp = await Directory.systemTemp.createTemp('kola-source-');
    addTearDown(() => temp.delete(recursive: true));
    final File linked = File('${temp.path}/linked.pdf');
    await linked.writeAsBytes(<int>[4, 5, 6]);

    final String path = await resolver.resolveReadablePath(
      DocumentSource(
        kind: DocumentSourceKind.linkedFile,
        uri: Uri.file(linked.path),
      ),
    );

    expect(path, linked.absolute.path);
  });

  test('missing source fails explicitly', () async {
    final Directory temp = await Directory.systemTemp.createTemp('kola-source-');
    addTearDown(() => temp.delete(recursive: true));

    expect(
      resolver.resolveReadablePath(
        DocumentSource(
          kind: DocumentSourceKind.linkedFile,
          uri: Uri.file('${temp.path}/missing.pdf'),
        ),
      ),
      throwsA(isA<DocumentSourceUnavailableException>()),
    );
  });
}
