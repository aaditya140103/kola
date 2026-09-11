import 'dart:convert';

import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

abstract final class DatabaseSerialization {
  static String encodeStrings(List<String> values) => jsonEncode(values);

  static List<String> decodeStrings(Object? value) {
    if (value == null) return const <String>[];
    final Object? decoded = jsonDecode(value as String);
    if (decoded is! List<Object?>) return const <String>[];
    return List<String>.unmodifiable(decoded.whereType<String>());
  }

  static String encodeDateTime(DateTime value) =>
      value.toUtc().toIso8601String();

  static String? encodeNullableDateTime(DateTime? value) =>
      value == null ? null : encodeDateTime(value);

  static String? encodeLocation(DocumentLocation? location) {
    if (location == null) return null;
    return jsonEncode(<String, Object?>{
      'scheme': location.scheme,
      'data': location.data,
      'label': location.label,
    });
  }

  static DocumentLocation? decodeLocation(Object? value) {
    if (value == null) return null;
    final Object? decoded = jsonDecode(value as String);
    if (decoded is! Map<String, Object?>) return null;
    final Object? rawData = decoded['data'];
    return DocumentLocation(
      scheme: decoded['scheme'] as String? ?? 'unknown',
      data: rawData is Map<String, Object?>
          ? rawData
          : const <String, Object?>{},
      label: decoded['label'] as String?,
    );
  }

  static String encodeAnchor(AnnotationAnchor anchor) {
    return jsonEncode(<String, Object?>{
      'documentId': anchor.documentId,
      'sourceLocator': anchor.sourceLocator == null
          ? null
          : <String, Object?>{
              'scheme': anchor.sourceLocator!.scheme,
              'data': anchor.sourceLocator!.data,
              'label': anchor.sourceLocator!.label,
            },
      'graphNodeIds': anchor.graphNodeIds,
      'exactQuote': anchor.exactQuote,
      'prefixContext': anchor.prefixContext,
      'suffixContext': anchor.suffixContext,
      'logicalStart': anchor.logicalStart,
      'logicalEnd': anchor.logicalEnd,
      'sourceGeometry': anchor.sourceGeometry,
      'formatSpecificFallback': anchor.formatSpecificFallback,
    });
  }

  static AnnotationAnchor decodeAnchor(Object value) {
    final Object? decoded = jsonDecode(value as String);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Invalid annotation anchor JSON.');
    }

    final Object? rawLocator = decoded['sourceLocator'];
    DocumentLocation? locator;
    if (rawLocator is Map<String, Object?>) {
      final Object? rawData = rawLocator['data'];
      locator = DocumentLocation(
        scheme: rawLocator['scheme'] as String? ?? 'unknown',
        data: rawData is Map<String, Object?>
            ? rawData
            : const <String, Object?>{},
        label: rawLocator['label'] as String?,
      );
    }

    final Object? rawNodeIds = decoded['graphNodeIds'];
    final Object? rawGeometry = decoded['sourceGeometry'];
    final Object? rawFallback = decoded['formatSpecificFallback'];

    return AnnotationAnchor(
      documentId: decoded['documentId'] as String,
      sourceLocator: locator,
      graphNodeIds: rawNodeIds is List<Object?>
          ? rawNodeIds.whereType<String>().toList(growable: false)
          : const <String>[],
      exactQuote: decoded['exactQuote'] as String?,
      prefixContext: decoded['prefixContext'] as String?,
      suffixContext: decoded['suffixContext'] as String?,
      logicalStart: decoded['logicalStart'] as int?,
      logicalEnd: decoded['logicalEnd'] as int?,
      sourceGeometry: rawGeometry is List<Object?>
          ? rawGeometry.whereType<Map<String, Object?>>().toList(growable: false)
          : const <Map<String, Object?>>[],
      formatSpecificFallback: rawFallback is Map<String, Object?>
          ? rawFallback
          : const <String, Object?>{},
    );
  }

  static DateTime dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    throw FormatException('Unsupported datetime value: $value');
  }

  static DateTime? nullableDateTime(Object? value) =>
      value == null ? null : dateTime(value);

  static bool boolean(Object? value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    return false;
  }

  static T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is! String) return fallback;
    for (final T value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
