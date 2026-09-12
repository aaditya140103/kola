import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/core/providers/annotation_providers.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/features/annotations/application/annotation_management_service.dart';
import 'package:kola/features/annotations/domain/annotation_models.dart';

class AnnotationPanel extends ConsumerWidget {
  const AnnotationPanel({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Annotation>> state = ref.watch(
      annotationsProvider(documentId),
    );

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KolaSpacing.lg,
              KolaSpacing.xs,
              KolaSpacing.lg,
              KolaSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Annotations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    state.when(
                      data: (List<Annotation> value) => Text(
                        '${value.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: KolaSpacing.md),
                Expanded(
                  child: state.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stackTrace) => Center(
                      child: Text(
                        'Kola could not load annotations.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (List<Annotation> annotations) {
                      if (annotations.isEmpty) {
                        return const _EmptyAnnotations();
                      }
                      return ListView.separated(
                        itemCount: annotations.length,
                        separatorBuilder: (_, _) => const SizedBox(
                          height: KolaSpacing.sm,
                        ),
                        itemBuilder: (BuildContext context, int index) =>
                            _AnnotationCard(annotation: annotations[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotationCard extends ConsumerWidget {
  const _AnnotationCard({required this.annotation});

  final Annotation annotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DocumentLocation? location = annotation.anchor.sourceLocator;
    final String locationLabel = _locationLabel(location);
    final String quote = annotation.quote?.trim().isNotEmpty == true
        ? annotation.quote!.trim()
        : 'Annotation';

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: KolaRadius.lg,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(KolaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ColorMarker(token: annotation.colorToken),
                const SizedBox(width: KolaSpacing.sm),
                Expanded(
                  child: Text(
                    quote,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                PopupMenuButton<_AnnotationAction>(
                  tooltip: 'Annotation actions',
                  onSelected: (_AnnotationAction action) =>
                      unawaited(_handleAction(context, ref, action)),
                  itemBuilder: (BuildContext context) => const <
                    PopupMenuEntry<_AnnotationAction>
                  >[
                    PopupMenuItem<_AnnotationAction>(
                      value: _AnnotationAction.note,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.note_alt_outlined),
                        title: Text('Add or edit note'),
                      ),
                    ),
                    PopupMenuItem<_AnnotationAction>(
                      value: _AnnotationAction.delete,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KolaSpacing.sm),
            Row(
              children: <Widget>[
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: KolaSpacing.xs),
                Text(
                  locationLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: location == null
                      ? null
                      : () => Navigator.of(context).pop(location),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Go to'),
                ),
              ],
            ),
            if (annotation.note?.trim().isNotEmpty == true) ...<Widget>[
              const SizedBox(height: KolaSpacing.sm),
              Container(
                padding: const EdgeInsets.all(KolaSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: KolaRadius.md,
                ),
                child: Text(annotation.note!.trim()),
              ),
            ],
            if (annotation.type == AnnotationType.highlight) ...<Widget>[
              const SizedBox(height: KolaSpacing.md),
              _HighlightColorPicker(annotation: annotation),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _AnnotationAction action,
  ) async {
    switch (action) {
      case _AnnotationAction.note:
        await _editNote(context, ref);
      case _AnnotationAction.delete:
        await _delete(context, ref);
    }
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController(
      text: annotation.note ?? '',
    );
    try {
      final String? note = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Annotation note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Add your note…',
              alignLabelWithHint: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (note == null || !context.mounted) return;
      final AnnotationManagementService service = ref.read(
        annotationManagementServiceProvider,
      );
      await service.setNote(annotation, note);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete annotation?'),
            content: const Text(
              'The highlight and its attached note will be removed from the reader.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final AnnotationManagementService service = ref.read(
      annotationManagementServiceProvider,
    );
    await service.delete(annotation);
  }

  static String _locationLabel(DocumentLocation? location) {
    if (location == null) return 'Unknown location';
    if (location.label?.trim().isNotEmpty == true) return location.label!.trim();
    final Object? rawPage = location.data['page'];
    if (rawPage is num) return 'Page ${rawPage.toInt()}';
    return location.scheme.toUpperCase();
  }
}

class _HighlightColorPicker extends ConsumerWidget {
  const _HighlightColorPicker({required this.annotation});

  final Annotation annotation;

  static const List<String> _tokens = <String>[
    'highlight.yellow',
    'highlight.blue',
    'highlight.green',
    'highlight.pink',
    'highlight.purple',
    'highlight.orange',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: KolaSpacing.sm,
      runSpacing: KolaSpacing.sm,
      children: _tokens
          .map(
            (String token) => Semantics(
              button: true,
              selected: annotation.colorToken == token,
              label: '${_colorName(token)} highlight',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: annotation.colorToken == token
                    ? null
                    : () => unawaited(_setColor(ref, token)),
                child: AnimatedContainer(
                  duration: KolaMotion.quick,
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: annotation.colorToken == token ? 2.5 : 1,
                      color: annotation.colorToken == token
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _color(token),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _setColor(WidgetRef ref, String token) async {
    final AnnotationManagementService service = ref.read(
      annotationManagementServiceProvider,
    );
    await service.setHighlightColor(annotation, token);
  }
}

class _ColorMarker extends StatelessWidget {
  const _ColorMarker({required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 52,
      decoration: BoxDecoration(
        color: _color(token),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _EmptyAnnotations extends StatelessWidget {
  const _EmptyAnnotations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.format_quote_rounded, size: 48),
            const SizedBox(height: KolaSpacing.md),
            Text(
              'No annotations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: KolaSpacing.sm),
            const Text(
              'Select text in the document and choose Highlight. Your annotations will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _AnnotationAction { note, delete }

Color _color(String? token) {
  return switch (token) {
    'highlight.blue' => Colors.lightBlueAccent,
    'highlight.green' => Colors.lightGreenAccent,
    'highlight.pink' => Colors.pinkAccent,
    'highlight.purple' => Colors.purpleAccent,
    'highlight.orange' => Colors.orangeAccent,
    _ => Colors.yellowAccent,
  };
}

String _colorName(String token) {
  return switch (token) {
    'highlight.blue' => 'Blue',
    'highlight.green' => 'Green',
    'highlight.pink' => 'Pink',
    'highlight.purple' => 'Purple',
    'highlight.orange' => 'Orange',
    _ => 'Yellow',
  };
}
