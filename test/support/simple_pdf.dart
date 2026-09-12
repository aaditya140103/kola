import 'dart:convert';

List<int> buildSimplePdf(String text, {String? outlineTitle}) {
  return buildPdfWithPages(<String>[text], outlineTitle: outlineTitle);
}

List<int> buildPdfWithPages(
  List<String> pageTexts, {
  String? outlineTitle,
}) {
  if (pageTexts.isEmpty) {
    throw ArgumentError.value(pageTexts, 'pageTexts', 'Must contain a page.');
  }

  final int pageCount = pageTexts.length;
  final int firstPageObject = 3;
  final int fontObject = firstPageObject + pageCount;
  final int firstContentObject = fontObject + 1;
  final int outlinesObject = firstContentObject + pageCount;
  final int outlineItemObject = outlinesObject + 1;
  final bool hasOutline = outlineTitle != null;

  final List<int> pageObjects = List<int>.generate(
    pageCount,
    (int index) => firstPageObject + index,
  );
  final List<int> contentObjects = List<int>.generate(
    pageCount,
    (int index) => firstContentObject + index,
  );

  final List<String> objects = <String>[
    hasOutline
        ? '<< /Type /Catalog /Pages 2 0 R /Outlines $outlinesObject 0 R >>'
        : '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [${pageObjects.map((int id) => '$id 0 R').join(' ')}] '
        '/Count $pageCount >>',
  ];

  for (int index = 0; index < pageCount; index += 1) {
    objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Resources << /Font << /F1 $fontObject 0 R >> >> '
      '/Contents ${contentObjects[index]} 0 R >>',
    );
  }

  objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

  for (final String text in pageTexts) {
    final String escaped = _escapePdfString(text);
    final String content = 'BT\n/F1 18 Tf\n72 720 Td\n($escaped) Tj\nET\n';
    objects.add(
      '<< /Length ${ascii.encode(content).length} >>\nstream\n${content}endstream',
    );
  }

  if (outlineTitle != null) {
    final String escapedOutline = _escapePdfString(outlineTitle);
    objects
      ..add(
        '<< /Type /Outlines /First $outlineItemObject 0 R '
        '/Last $outlineItemObject 0 R /Count 1 >>',
      )
      ..add(
        '<< /Title ($escapedOutline) /Parent $outlinesObject 0 R '
        '/Dest [$firstPageObject 0 R /Fit] >>',
      );
  }

  final StringBuffer buffer = StringBuffer('%PDF-1.4\n');
  final List<int> offsets = <int>[];
  for (int index = 0; index < objects.length; index += 1) {
    offsets.add(buffer.length);
    buffer
      ..writeln('${index + 1} 0 obj')
      ..writeln(objects[index])
      ..writeln('endobj');
  }

  final int xrefOffset = buffer.length;
  buffer
    ..writeln('xref')
    ..writeln('0 ${objects.length + 1}')
    ..writeln('0000000000 65535 f ');
  for (final int offset in offsets) {
    buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
  }
  buffer
    ..writeln('trailer')
    ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
    ..writeln('startxref')
    ..writeln(xrefOffset)
    ..writeln('%%EOF');

  return ascii.encode(buffer.toString());
}

String _escapePdfString(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}
