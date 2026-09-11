import 'package:kola/document/registry/document_adapter.dart';

enum AnnotationType {
  highlight,
  underline,
  strikeout,
  textNote,
  marginNote,
  ink,
  shape,
  arrow,
  area,
  textBox,
}

final class Annotation {
  const Annotation({
    required this.id,
    required this.documentId,
    required this.type,
    required this.anchor,
    required this.createdAt,
    required this.updatedAt,
    this.quote,
    this.note,
    this.semanticLabel,
    this.colorToken,
    this.favorite = false,
    this.revision = 1,
    this.deletedAt,
  });

  final String id;
  final String documentId;
  final AnnotationType type;
  final AnnotationAnchor anchor;
  final String? quote;
  final String? note;
  final String? semanticLabel;
  final String? colorToken;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final DateTime? deletedAt;
}
