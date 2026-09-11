import 'package:drift/drift.dart';
import 'package:kola/core/database/database_serialization.dart';
import 'package:kola/core/database/kola_database.dart'
    hide ReadingCoverage, ReadingGoal, ReadingSession, ReadingState, PlannedReadingItem;
import 'package:kola/features/progress/domain/reading_models.dart';
import 'package:kola/features/progress/domain/reading_repository.dart';

final class DriftReadingRepository implements ReadingRepository {
  DriftReadingRepository(this._database);

  final KolaDatabase _database;

  @override
  Stream<ReadingState?> watchState(String documentId) {
    return _database
        .customSelect(
          'SELECT * FROM reading_states WHERE document_id = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<String>(documentId)],
          readsFrom: {_database.readingStates},
        )
        .watchSingleOrNull()
        .map((QueryRow? row) => row == null ? null : _stateFromRow(row));
  }

  @override
  Future<void> saveState(ReadingState state) async {
    await _database.customStatement(
      '''
      INSERT INTO reading_states (
        document_id, locator_json, position_progress, view_mode,
        zoom, active_theme_id, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(document_id) DO UPDATE SET
        locator_json = excluded.locator_json,
        position_progress = excluded.position_progress,
        view_mode = excluded.view_mode,
        zoom = excluded.zoom,
        active_theme_id = excluded.active_theme_id,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        state.documentId,
        DatabaseSerialization.encodeLocation(state.location),
        state.positionProgress.clamp(0.0, 1.0),
        state.viewMode.name,
        state.zoom,
        state.activeThemeId,
        DatabaseSerialization.encodeDateTime(state.updatedAt),
      ],
    );
    _database.markTablesUpdated([_database.readingStates]);
  }

  @override
  Stream<ReadingCoverage?> watchCoverage(String documentId) {
    return _database
        .customSelect(
          '''
          SELECT * FROM reading_coverage
          WHERE document_id = ?
          ORDER BY updated_at DESC
          LIMIT 1
          ''',
          variables: <Variable<Object>>[Variable<String>(documentId)],
          readsFrom: {_database.readingCoverage},
        )
        .watchSingleOrNull()
        .map((QueryRow? row) => row == null ? null : _coverageFromRow(row));
  }

  @override
  Future<void> saveCoverage(ReadingCoverage coverage) async {
    await _database.customStatement(
      '''
      INSERT INTO reading_coverage (
        document_id, graph_version, coverage_blob, covered_weight,
        total_weight, completion_state, reading_time_ms, updated_at
      ) VALUES (?, ?, NULL, ?, ?, ?, ?, ?)
      ON CONFLICT(document_id, graph_version) DO UPDATE SET
        covered_weight = excluded.covered_weight,
        total_weight = excluded.total_weight,
        completion_state = excluded.completion_state,
        reading_time_ms = excluded.reading_time_ms,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        coverage.documentId,
        coverage.graphVersion,
        coverage.coveredWeight,
        coverage.totalWeight,
        coverage.completionState.name,
        coverage.readingTime.inMilliseconds,
        DatabaseSerialization.encodeDateTime(coverage.updatedAt),
      ],
    );
    _database.markTablesUpdated([_database.readingCoverage]);
  }

  @override
  Stream<List<ReadingSession>> watchSessions(String documentId) {
    return _database
        .customSelect(
          '''
          SELECT * FROM reading_sessions
          WHERE document_id = ?
          ORDER BY started_at DESC
          ''',
          variables: <Variable<Object>>[Variable<String>(documentId)],
          readsFrom: {_database.readingSessions},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<ReadingSession>.unmodifiable(
            rows.map(_sessionFromRow),
          ),
        );
  }

  @override
  Stream<List<ReadingSession>> watchAllSessions() {
    return _database
        .customSelect(
          'SELECT * FROM reading_sessions ORDER BY started_at DESC',
          readsFrom: {_database.readingSessions},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<ReadingSession>.unmodifiable(
            rows.map(_sessionFromRow),
          ),
        );
  }

  @override
  Future<void> saveSession(ReadingSession session) async {
    await _database.customStatement(
      '''
      INSERT INTO reading_sessions (
        id, document_id, started_at, ended_at, active_ms, passive_ms,
        start_locator_json, end_locator_json, revision, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        document_id = excluded.document_id,
        started_at = excluded.started_at,
        ended_at = excluded.ended_at,
        active_ms = excluded.active_ms,
        passive_ms = excluded.passive_ms,
        start_locator_json = excluded.start_locator_json,
        end_locator_json = excluded.end_locator_json,
        revision = excluded.revision,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        session.id,
        session.documentId,
        DatabaseSerialization.encodeDateTime(session.startedAt),
        DatabaseSerialization.encodeNullableDateTime(session.endedAt),
        session.activeTime.inMilliseconds,
        session.passiveTime.inMilliseconds,
        DatabaseSerialization.encodeLocation(session.startLocation),
        DatabaseSerialization.encodeLocation(session.endLocation),
        session.revision,
        DatabaseSerialization.encodeDateTime(session.updatedAt),
      ],
    );
    _database.markTablesUpdated([_database.readingSessions]);
  }

  @override
  Stream<List<PlannedReadingItem>> watchReadingList() {
    return _database
        .customSelect(
          '''
          SELECT * FROM planned_reading_items
          ORDER BY
            CASE status
              WHEN 'nextUp' THEN 0
              WHEN 'reading' THEN 1
              WHEN 'wantToRead' THEN 2
              WHEN 'paused' THEN 3
              WHEN 'completed' THEN 4
              ELSE 5
            END,
            CASE WHEN queue_position IS NULL THEN 1 ELSE 0 END,
            queue_position ASC,
            added_at DESC
          ''',
          readsFrom: {_database.plannedReadingItems},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<PlannedReadingItem>.unmodifiable(
            rows.map(_plannedItemFromRow),
          ),
        );
  }

  @override
  Future<void> savePlannedItem(PlannedReadingItem item) async {
    await _database.customStatement(
      '''
      INSERT INTO planned_reading_items (
        id, linked_document_id, title, authors_json, status,
        queue_position, notes, added_at, updated_at, revision
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        linked_document_id = excluded.linked_document_id,
        title = excluded.title,
        authors_json = excluded.authors_json,
        status = excluded.status,
        queue_position = excluded.queue_position,
        notes = excluded.notes,
        added_at = excluded.added_at,
        updated_at = excluded.updated_at,
        revision = excluded.revision
      ''',
      <Object?>[
        item.id,
        item.linkedDocumentId,
        item.title,
        DatabaseSerialization.encodeStrings(item.authors),
        item.status.name,
        item.queuePosition,
        item.notes,
        DatabaseSerialization.encodeDateTime(item.addedAt),
        DatabaseSerialization.encodeDateTime(item.updatedAt),
        item.revision,
      ],
    );
    _database.markTablesUpdated([_database.plannedReadingItems]);
  }

  @override
  Future<void> removePlannedItem(String id) async {
    await _database.customStatement(
      'DELETE FROM planned_reading_items WHERE id = ?',
      <Object?>[id],
    );
    _database.markTablesUpdated([_database.plannedReadingItems]);
  }

  @override
  Stream<List<ReadingGoal>> watchGoals() {
    return _database
        .customSelect(
          'SELECT * FROM reading_goals ORDER BY updated_at DESC',
          readsFrom: {_database.readingGoals},
        )
        .watch()
        .map(
          (List<QueryRow> rows) => List<ReadingGoal>.unmodifiable(
            rows.map(_goalFromRow),
          ),
        );
  }

  @override
  Future<void> saveGoal(ReadingGoal goal) async {
    await _database.customStatement(
      '''
      INSERT INTO reading_goals (
        id, metric, target_value, period, enabled,
        starts_at, ends_at, updated_at, revision
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        metric = excluded.metric,
        target_value = excluded.target_value,
        period = excluded.period,
        enabled = excluded.enabled,
        starts_at = excluded.starts_at,
        ends_at = excluded.ends_at,
        updated_at = excluded.updated_at,
        revision = excluded.revision
      ''',
      <Object?>[
        goal.id,
        goal.metric.name,
        goal.targetValue,
        goal.period.name,
        goal.enabled,
        DatabaseSerialization.encodeNullableDateTime(goal.startsAt),
        DatabaseSerialization.encodeNullableDateTime(goal.endsAt),
        DatabaseSerialization.encodeDateTime(goal.updatedAt),
        goal.revision,
      ],
    );
    _database.markTablesUpdated([_database.readingGoals]);
  }

  ReadingState _stateFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return ReadingState(
      documentId: data['document_id']! as String,
      location: DatabaseSerialization.decodeLocation(data['locator_json']),
      positionProgress: (data['position_progress']! as num).toDouble(),
      viewMode: DatabaseSerialization.enumValue(
        ReaderViewMode.values,
        data['view_mode'],
        ReaderViewMode.flow,
      ),
      zoom: (data['zoom']! as num).toDouble(),
      activeThemeId: data['active_theme_id'] as String?,
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
    );
  }

  ReadingCoverage _coverageFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return ReadingCoverage(
      documentId: data['document_id']! as String,
      graphVersion: data['graph_version']! as String,
      coveredWeight: (data['covered_weight']! as num).toDouble(),
      totalWeight: (data['total_weight']! as num).toDouble(),
      completionState: DatabaseSerialization.enumValue(
        ReadingCompletionState.values,
        data['completion_state'],
        ReadingCompletionState.inProgress,
      ),
      readingTime: Duration(milliseconds: data['reading_time_ms'] as int? ?? 0),
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
    );
  }

  ReadingSession _sessionFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return ReadingSession(
      id: data['id']! as String,
      documentId: data['document_id']! as String,
      startedAt: DatabaseSerialization.dateTime(data['started_at']),
      endedAt: DatabaseSerialization.nullableDateTime(data['ended_at']),
      activeTime: Duration(milliseconds: data['active_ms'] as int? ?? 0),
      passiveTime: Duration(milliseconds: data['passive_ms'] as int? ?? 0),
      startLocation: DatabaseSerialization.decodeLocation(
        data['start_locator_json'],
      ),
      endLocation: DatabaseSerialization.decodeLocation(data['end_locator_json']),
      revision: data['revision'] as int? ?? 1,
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
    );
  }

  PlannedReadingItem _plannedItemFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return PlannedReadingItem(
      id: data['id']! as String,
      linkedDocumentId: data['linked_document_id'] as String?,
      title: data['title']! as String,
      authors: DatabaseSerialization.decodeStrings(data['authors_json']),
      status: DatabaseSerialization.enumValue(
        ReadingListStatus.values,
        data['status'],
        ReadingListStatus.wantToRead,
      ),
      queuePosition: data['queue_position'] as int?,
      notes: data['notes'] as String?,
      addedAt: DatabaseSerialization.dateTime(data['added_at']),
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
      revision: data['revision'] as int? ?? 1,
    );
  }

  ReadingGoal _goalFromRow(QueryRow row) {
    final Map<String, Object?> data = row.data;
    return ReadingGoal(
      id: data['id']! as String,
      metric: DatabaseSerialization.enumValue(
        ReadingGoalMetric.values,
        data['metric'],
        ReadingGoalMetric.minutes,
      ),
      targetValue: (data['target_value']! as num).toDouble(),
      period: DatabaseSerialization.enumValue(
        ReadingGoalPeriod.values,
        data['period'],
        ReadingGoalPeriod.weekly,
      ),
      enabled: DatabaseSerialization.boolean(data['enabled']),
      startsAt: DatabaseSerialization.nullableDateTime(data['starts_at']),
      endsAt: DatabaseSerialization.nullableDateTime(data['ends_at']),
      updatedAt: DatabaseSerialization.dateTime(data['updated_at']),
      revision: data['revision'] as int? ?? 1,
    );
  }
}
