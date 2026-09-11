import 'package:kola/document/model/document_models.dart';

enum FormatConfidence { exact, high, medium, low }

enum FormatEvidence { signature, container, extension }

final class FormatMatch {
  const FormatMatch({
    required this.format,
    required this.confidence,
    this.evidence = const <FormatEvidence>{},
  });

  final DocumentFormat format;
  final FormatConfidence confidence;
  final Set<FormatEvidence> evidence;

  bool get isRecognized => format != DocumentFormat.unknown;
}
