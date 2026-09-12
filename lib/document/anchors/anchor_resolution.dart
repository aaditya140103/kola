import 'package:kola/document/model/document_models.dart';

enum AnchorResolutionStrategy {
  storedLocator,
  logicalRange,
  quoteContext,
}

final class AnchorResolution {
  AnchorResolution.resolved({
    required this.location,
    required this.strategy,
    required this.confidence,
    this.reason,
  }) : resolved = true;

  const AnchorResolution.unresolved({required this.reason})
    : resolved = false,
      location = null,
      strategy = null,
      confidence = 0.0;

  final bool resolved;
  final DocumentLocation? location;
  final AnchorResolutionStrategy? strategy;
  final double confidence;
  final String? reason;
}
