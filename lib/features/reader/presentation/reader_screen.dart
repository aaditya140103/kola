import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/core/providers/annotation_providers.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/core/providers/document_engine_providers.dart';
import 'package:kola/core/providers/repository_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/anchors/anchor_resolution.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';
import 'package:kola/document/text/document_text_selection.dart';
import 'package:kola/features/annotations/application/annotation_creation_service.dart';
import 'package:kola/features/annotations/application/annotation_navigation_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';
import 'package:kola/features/annotations/presentation/annotation_panel.dart';
import 'package:kola/features/progress/domain/reading_models.dart';
import 'package:kola/features/progress/domain/reading_repository.dart';
import 'package:kola/features/reader/presentation/reader_search_sheet.dart';
import 'package:kola/features/search/domain/search_models.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.documentId,
    this.initialLocation,
    super.key,
  });

  final String documentId;
  final DocumentLocation? initialLocation;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const Duration _stateSaveDebounce = Duration(milliseconds: 400);

  bool? _flowModeOverride;
  Timer? _readingStateTimer;
  FidelityViewState? _pendingFidelityState;
  ReadingState? _pendingBaseState;
  FidelityNavigationRequest? _navigationRequest;
  int _navigationSequence = 0;
  late final ReadingRepository _readingRepository;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _readingRepository = ref.read(readingRepositoryProvider);
  }

  @override
  void dispose() {
    _readingStateTimer?.cancel();
    if (_pendingFidelityState != null) {
      final ReadingRepository repository = _readingRepository;
      unawaited(_flushPendingReadingState(repository));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<KolaDocument?> document = ref.watch(
      documentProvider(widget.documentId),
    );
    final AsyncValue<ReadingState?> readingState = ref.watch(
      readingStateProvider(widget.documentId),
    );

    return document.when(
      data: (KolaDocument? value) {
        if (value == null) {
          return _ReaderMessage(
            title: 'Document not found',
            message: 'This library item no longer exists.',
            onBack: _leaveReader,
          );
        }
        return readingState.when(
          data: (ReadingState? state) => _buildReader(context, value, state),
          loading: () => _loadingReader(),
          error: (Object error, StackTrace stackTrace) =>
              _buildReader(context, value, null, resumeFailed: true),
        );
      },
      loading: () => _loadingReader(),
      error: (Object error, StackTrace stackTrace) => _ReaderMessage(
        title: 'Could not load document',
        message: error.toString(),
        onBack: _leaveReader,
      ),
    );
  }

  Widget _buildReader(
    BuildContext context,
    KolaDocument document,
    ReadingState? readingState, {
    bool resumeFailed = false,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final FormatCapabilities capabilities =
        ref.watch(formatRegistryProvider).capabilitiesFor(document.format) ??
        const FormatCapabilities();
    final DocumentFidelityRenderer? fidelityRenderer = ref
        .watch(fidelityRendererRegistryProvider)
        .rendererFor(document.format);
    final AsyncValue<List<Annotation>> annotationState = ref.watch(
      annotationsProvider(document.id),
    );
    final List<Annotation> annotations = annotationState.when(
      data: (List<Annotation> value) => value,
      loading: () => const <Annotation>[],
      error: (Object error, StackTrace stackTrace) => const <Annotation>[],
    );
    final AsyncValue<Map<String, List<Map<String, Object?>>>> geometryState =
        ref.watch(recoveredAnnotationGeometryProvider(document.id));
    final Map<String, List<Map<String, Object?>>> recoveredGeometry =
        geometryState.when(
          data: (Map<String, List<Map<String, Object?>>> value) => value,
          loading: () => const <String, List<Map<String, Object?>>>{},
          error: (Object error, StackTrace stackTrace) =>
              const <String, List<Map<String, Object?>>>{},
        );
    final Map<String, Annotation> annotationsById = <String, Annotation>{
      for (final Annotation annotation in annotations)
        annotation.id: annotation,
    };
    final List<FidelityTextHighlight> highlights = recoveredGeometry.entries
        .where((entry) => annotationsById.containsKey(entry.key))
        .map((entry) {
          final Annotation annotation = annotationsById[entry.key]!;
          return FidelityTextHighlight(
            id: annotation.id,
            sourceGeometry: entry.value,
            colorToken: annotation.colorToken,
          );
        })
        .toList(growable: false);

    final bool persistedFlowMode =
        readingState?.viewMode == ReaderViewMode.flow && capabilities.flowMode;
    final bool flowMode = _flowModeOverride ?? persistedFlowMode;

    final Widget surface = flowMode
        ? const _FlowUnavailable()
        : fidelityRenderer?.build(
                context,
                document,
                initialState: _toFidelityViewState(readingState),
                navigationRequest: _navigationRequest,
                onStateChanged: (FidelityViewState state) =>
                    _scheduleFidelityStateSave(state, readingState),
                onTextSelection: capabilities.textSelection
                    ? (DocumentTextSelection selection) =>
                          unawaited(_createHighlight(document, selection))
                    : null,
                highlights: highlights,
              ) ??
              _FidelityUnavailable(document: document);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ReaderTopBar(
              document: document,
              flowMode: flowMode,
              flowAvailable: capabilities.flowMode,
              searchAvailable: capabilities.textSearch,
              annotationsAvailable: capabilities.textAnnotations,
              annotationCount: annotations.length,
              onBack: () => unawaited(_closeReader()),
              onSearch: () => unawaited(_openSearch(document)),
              onAnnotations: () => unawaited(_openAnnotations(document)),
              onModeChanged: (bool value) {
                if (value && !capabilities.flowMode) return;
                setState(() => _flowModeOverride = value);
                unawaited(_saveViewMode(value, readingState));
              },
            ),
            if (resumeFailed)
              Material(
                color: scheme.errorContainer,
                child: const Padding(
                  padding: EdgeInsets.all(KolaSpacing.sm),
                  child: Text(
                    'Could not restore reading position. Opening from the beginning.',
                  ),
                ),
              ),
            Expanded(child: surface),
          ],
        ),
      ),
    );
  }

  FidelityViewState? _toFidelityViewState(ReadingState? state) {
    final DocumentLocation? location =
        widget.initialLocation ?? state?.location;
    if (state == null && location == null) return null;
    return FidelityViewState(
      location: location,
      positionProgress: state?.positionProgress ?? 0.0,
      zoom: state?.zoom ?? 1.0,
    );
  }

  Future<void> _createHighlight(
    KolaDocument document,
    DocumentTextSelection selection,
  ) async {
    try {
      final AnnotationCreationService service = ref.read(
        annotationCreationServiceProvider,
      );
      await service.createHighlight(document: document, selection: selection);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Highlight saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Kola could not save this highlight: $error')),
        );
    }
  }

  Future<void> _openSearch(KolaDocument document) async {
    final SearchHit? hit = await showModalBottomSheet<SearchHit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) => ReaderSearchSheet(document: document),
    );
    if (!mounted || hit == null) return;
    _navigateTo(hit.location);
  }

  Future<void> _openAnnotations(KolaDocument document) async {
    final Annotation? annotation = await showModalBottomSheet<Annotation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) =>
          AnnotationPanel(documentId: document.id),
    );
    if (!mounted || annotation == null) return;

    try {
      final AnnotationNavigationService service = ref.read(
        annotationNavigationServiceProvider,
      );
      final AnchorResolution resolution = await service.resolve(
        document,
        annotation,
      );
      if (!mounted) return;

      final DocumentLocation? location = resolution.location;
      if (!resolution.resolved || location == null) {
        _showUnresolvedAnnotation(resolution.reason);
        return;
      }

      _navigateTo(location);
      if (resolution.strategy != AnchorResolutionStrategy.storedLocator) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Annotation recovered at its current source location.',
              ),
            ),
          );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Kola could not resolve this annotation: $error'),
          ),
        );
    }
  }

  void _showUnresolvedAnnotation(String? reason) {
    final String detail = reason?.trim().isNotEmpty == true
        ? ' ${reason!.trim()}'
        : '';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Kola could not safely locate this annotation in the current document.$detail',
          ),
        ),
      );
  }

  void _navigateTo(DocumentLocation location) {
    setState(() {
      _flowModeOverride = false;
      _navigationSequence += 1;
      _navigationRequest = FidelityNavigationRequest(
        location: location,
        sequence: _navigationSequence,
      );
    });
  }

  void _scheduleFidelityStateSave(
    FidelityViewState state,
    ReadingState? baseState,
  ) {
    _pendingFidelityState = state;
    _pendingBaseState = baseState;
    _readingStateTimer?.cancel();
    _readingStateTimer = Timer(_stateSaveDebounce, () {
      final ReadingRepository repository = _readingRepository;
      unawaited(_flushPendingReadingState(repository));
    });
  }

  Future<ReadingState?> _flushPendingReadingState(
    ReadingRepository repository,
  ) async {
    _readingStateTimer?.cancel();
    _readingStateTimer = null;

    final FidelityViewState? pending = _pendingFidelityState;
    final ReadingState? baseState = _pendingBaseState;
    if (pending == null) return null;

    _pendingFidelityState = null;
    _pendingBaseState = null;

    final ReadingState state = ReadingState(
      documentId: widget.documentId,
      location: pending.location,
      positionProgress: pending.positionProgress,
      viewMode: ReaderViewMode.fidelity,
      zoom: pending.zoom,
      activeThemeId: baseState?.activeThemeId,
      updatedAt: DateTime.now().toUtc(),
    );
    try {
      await repository.saveState(state);
      return state;
    } catch (error) {
      // A metadata write failure must never trap the user in the reader.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save reading position.')),
        );
      }
      return null;
    }
  }

  Future<void> _saveViewMode(bool flowMode, ReadingState? current) async {
    final ReadingRepository repository = _readingRepository;
    final ReadingState? flushed = _pendingFidelityState == null
        ? null
        : await _flushPendingReadingState(repository);
    final ReadingState? base = flushed ?? current;

    await repository.saveState(
      ReadingState(
        documentId: widget.documentId,
        location: base?.location,
        positionProgress: base?.positionProgress ?? 0.0,
        viewMode: flowMode ? ReaderViewMode.flow : ReaderViewMode.fidelity,
        zoom: base?.zoom ?? 1.0,
        activeThemeId: base?.activeThemeId,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Widget _loadingReader() => Scaffold(
    appBar: AppBar(leading: BackButton(onPressed: _leaveReader)),
    body: const Center(child: CircularProgressIndicator()),
  );

  void _leaveReader() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  Future<void> _closeReader() async {
    if (_closing) return;
    _closing = true;
    if (_pendingFidelityState != null) {
      final ReadingRepository repository = _readingRepository;
      await _flushPendingReadingState(repository);
    }
    if (mounted) _leaveReader();
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.document,
    required this.flowMode,
    required this.flowAvailable,
    required this.searchAvailable,
    required this.annotationsAvailable,
    required this.annotationCount,
    required this.onBack,
    required this.onSearch,
    required this.onAnnotations,
    required this.onModeChanged,
  });

  final KolaDocument document;
  final bool flowMode;
  final bool flowAvailable;
  final bool searchAvailable;
  final bool annotationsAvailable;
  final int annotationCount;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onAnnotations;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String subtitle = document.metadata.authors.isEmpty
        ? document.format.name.toUpperCase()
        : document.metadata.authors.join(', ');

    return Padding(
      padding: const EdgeInsets.all(KolaSpacing.md),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: KolaRadius.pill,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolaSpacing.xs,
            vertical: KolaSpacing.xxs,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = <Widget>[
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: KolaSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        document.metadata.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ];
              final actions = <Widget>[
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    const ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.description_rounded),
                      tooltip: 'Fidelity',
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      enabled: flowAvailable,
                      icon: const Icon(Icons.auto_stories_rounded),
                      tooltip: flowAvailable
                          ? 'Flow'
                          : 'Flow not available yet',
                    ),
                  ],
                  selected: <bool>{flowMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<bool> selection) =>
                      onModeChanged(selection.first),
                ),
                IconButton(
                  onPressed: searchAvailable ? onSearch : null,
                  tooltip: searchAvailable
                      ? 'Search this document'
                      : 'Search is not available for this format yet',
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  onPressed: annotationsAvailable ? onAnnotations : null,
                  tooltip: annotationsAvailable
                      ? 'Annotations'
                      : 'Annotations are not available for this format yet',
                  icon: Badge.count(
                    count: annotationCount,
                    isLabelVisible: annotationCount > 0,
                    child: const Icon(Icons.format_quote_rounded),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: 'More',
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ];
              if (constraints.maxWidth < 440) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(children: title),
                    Wrap(alignment: WrapAlignment.center, children: actions),
                  ],
                );
              }
              return Row(children: <Widget>[...title, ...actions]);
            },
          ),
        ),
      ),
    );
  }
}

class _FidelityUnavailable extends StatelessWidget {
  const _FidelityUnavailable({required this.document});

  final KolaDocument document;

  @override
  Widget build(BuildContext context) {
    return _CenteredReaderNotice(
      icon: Icons.description_outlined,
      title: 'Fidelity view is not available yet',
      message:
          '${document.format.name.toUpperCase()} was imported successfully, but its renderer has not been integrated yet.',
    );
  }
}

class _FlowUnavailable extends StatelessWidget {
  const _FlowUnavailable();

  @override
  Widget build(BuildContext context) {
    return const _CenteredReaderNotice(
      icon: Icons.auto_stories_outlined,
      title: 'Flow Mode is not available yet',
      message: 'Kola will enable Flow only after source-mapped semantic extraction is implemented for this format.',
    );
  }
}

class _CenteredReaderNotice extends StatelessWidget {
  const _CenteredReaderNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(KolaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 52),
              const SizedBox(height: KolaSpacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolaSpacing.sm),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _CenteredReaderNotice(
        icon: Icons.error_outline_rounded,
        title: title,
        message: message,
      ),
    );
  }
}
