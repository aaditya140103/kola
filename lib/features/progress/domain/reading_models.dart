import 'package:kola/document/model/document_models.dart';

enum ReaderViewMode { flow, fidelity }

enum ReadingCompletionState { unread, inProgress, completed }

enum ReadingListStatus {
  wantToRead,
  nextUp,
  reading,
  paused,
  completed,
  abandoned,
}

enum ReadingGoalMetric { minutes, hours, documents }

enum ReadingGoalPeriod { daily, weekly, monthly, yearly }

final class ReadingState {
  const ReadingState({
    required this.documentId,
    required this.positionProgress,
    required this.viewMode,
    required this.zoom,
    required this.updatedAt,
    this.location,
    this.activeThemeId,
  });

  final String documentId;
  final DocumentLocation? location;
  final double positionProgress;
  final ReaderViewMode viewMode;
  final double zoom;
  final String? activeThemeId;
  final DateTime updatedAt;
}

final class ReadingCoverage {
  const ReadingCoverage({
    required this.documentId,
    required this.graphVersion,
    required this.coveredWeight,
    required this.totalWeight,
    required this.completionState,
    required this.readingTime,
    required this.updatedAt,
  });

  final String documentId;
  final String graphVersion;
  final double coveredWeight;
  final double totalWeight;
  final ReadingCompletionState completionState;
  final Duration readingTime;
  final DateTime updatedAt;

  double get fraction {
    if (totalWeight <= 0) {
      return 0;
    }
    return (coveredWeight / totalWeight).clamp(0.0, 1.0).toDouble();
  }
}

final class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.documentId,
    required this.startedAt,
    required this.activeTime,
    required this.passiveTime,
    required this.updatedAt,
    this.endedAt,
    this.startLocation,
    this.endLocation,
    this.revision = 1,
  });

  final String id;
  final String documentId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration activeTime;
  final Duration passiveTime;
  final DocumentLocation? startLocation;
  final DocumentLocation? endLocation;
  final int revision;
  final DateTime updatedAt;
}

final class PlannedReadingItem {
  const PlannedReadingItem({
    required this.id,
    required this.title,
    required this.status,
    required this.addedAt,
    required this.updatedAt,
    this.linkedDocumentId,
    this.authors = const <String>[],
    this.queuePosition,
    this.notes,
    this.revision = 1,
  });

  final String id;
  final String? linkedDocumentId;
  final String title;
  final List<String> authors;
  final ReadingListStatus status;
  final int? queuePosition;
  final String? notes;
  final DateTime addedAt;
  final DateTime updatedAt;
  final int revision;
}

final class ReadingGoal {
  const ReadingGoal({
    required this.id,
    required this.metric,
    required this.targetValue,
    required this.period,
    required this.updatedAt,
    this.enabled = true,
    this.startsAt,
    this.endsAt,
    this.revision = 1,
  });

  final String id;
  final ReadingGoalMetric metric;
  final double targetValue;
  final ReadingGoalPeriod period;
  final bool enabled;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime updatedAt;
  final int revision;
}
