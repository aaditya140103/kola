import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kola/app/kola_app.dart';
import 'package:kola/app/router.dart';
import 'package:kola/core/providers/annotation_providers.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/core/providers/document_engine_providers.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/text/document_text_selection.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/progress/domain/reading_models.dart';
import 'package:kola/features/progress/domain/reading_repository.dart';

final _document = KolaDocument(
  id: 'sha256:reader-test',
  source: DocumentSource(
    kind: DocumentSourceKind.linkedFile,
    uri: Uri.file('/sample.pdf'),
  ),
  format: DocumentFormat.pdf,
  metadata: const DocumentMetadata(title: 'Navigation sample'),
  importedAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Future<void> _mount(
  WidgetTester tester, {
  String route = '/library',
  Future<KolaDocument?>? document,
  Stream<ReadingState?>? readingState,
  _ReadingRepository? repository,
}) async {
  kolaRouter.go(route);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsProvider.overrideWith((ref) => Stream.value([_document])),
        documentProvider(_document.id)
            .overrideWith((ref) => document ?? Future.value(_document)),
        readingStateProvider(_document.id)
            .overrideWith((ref) => readingState ?? Stream.value(null)),
        readingRepositoryProvider.overrideWithValue(
          repository ?? _ReadingRepository(),
        ),
        readingListProvider.overrideWith(
          (ref) => Stream.value(<PlannedReadingItem>[]),
        ),
        allReadingSessionsProvider.overrideWith(
          (ref) => Stream.value(<ReadingSession>[]),
        ),
        annotationsProvider(_document.id)
            .overrideWith((ref) => Stream.value(<Annotation>[])),
        recoveredAnnotationGeometryProvider(_document.id)
            .overrideWith((ref) async => {}),
        fidelityRendererRegistryProvider.overrideWithValue(
          FidelityRendererRegistry([_Renderer()]),
        ),
      ],
      child: const KolaApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('compact PDF reader keeps controls and content usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, route: '/reader/${_document.id}');
    expect(tester.getCenter(find.text('PDF surface')).dy, greaterThan(200));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
  });

  testWidgets('Library PDF opens and Back returns to Library', (tester) async {
    await _mount(tester);
    await tester.tap(find.text('Navigation sample'));
    await tester.pumpAndSettle();
    expect(find.text('PDF surface'), findsOneWidget);
    expect(tester.getCenter(find.text('PDF surface')).dy, greaterThan(200));
    expect(kolaRouter.canPop(), isTrue);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home PDF opens and system Back returns Home', (tester) async {
    await _mount(tester, route: '/');
    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();
    expect(find.text('PDF surface'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets(
    'system Back flushes a pending page without reading disposed ref',
    (tester) async {
      final repository = _ReadingRepository();
      await _mount(tester, repository: repository);
      await tester.tap(find.text('Navigation sample'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn page'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.positionProgress, 0.5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct reader route Back falls back to Library', (tester) async {
    await _mount(tester, route: '/reader/${_document.id}');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
    expect(tester.takeException(), isNull);
  });

  testWidgets('document loading can be left before lookup completes', (
    tester,
  ) async {
    final pending = Completer<KolaDocument?>();
    await _mount(
      tester,
      route: '/reader/${_document.id}',
      document: pending.future,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
    pending.complete(_document);
    await tester.pumpAndSettle();
  });

  testWidgets('missing document can return to Library', (tester) async {
    await _mount(
      tester,
      route: '/reader/${_document.id}',
      document: Future.value(null),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed resume does not block readable PDF', (tester) async {
    await _mount(
      tester,
      route: '/reader/${_document.id}',
      readingState: Stream.error(StateError('bad saved position')),
    );
    expect(find.text('PDF surface'), findsOneWidget);
    expect(find.textContaining('Could not restore'), findsOneWidget);
  });

  testWidgets('Back remains available after tapping document surface', (
    tester,
  ) async {
    await _mount(tester, route: '/reader/${_document.id}');
    await tester.tap(find.text('PDF surface'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed position save does not trap reader or escape as async error',
    (tester) async {
      final repository = _ReadingRepository()..fail = true;
      await _mount(
        tester,
        route: '/reader/${_document.id}',
        repository: repository,
      );
      await tester.tap(find.text('Turn page'));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(kolaRouter.routeInformationProvider.value.uri.path, '/library');
      expect(repository.saved, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReadingRepository implements ReadingRepository {
  bool fail = false;
  final List<ReadingState> saved = [];
  @override
  Future<void> saveState(ReadingState state) async {
    saved.add(state);
    if (fail) throw StateError('disk full');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Renderer implements DocumentFidelityRenderer {
  @override
  DocumentFormat get format => DocumentFormat.pdf;
  @override
  Widget build(
    BuildContext context,
    KolaDocument document, {
    FidelityViewState? initialState,
    FidelityNavigationRequest? navigationRequest,
    ValueChanged<FidelityViewState>? onStateChanged,
    ValueChanged<DocumentTextSelection>? onTextSelection,
    List<FidelityTextHighlight> highlights = const [],
  }) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('PDF surface'),
        TextButton(
          onPressed: () => onStateChanged?.call(
            const FidelityViewState(positionProgress: 0.5, zoom: 1),
          ),
          child: const Text('Turn page'),
        ),
      ],
    ),
  );
}
