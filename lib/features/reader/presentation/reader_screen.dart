import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/core/providers/app_data_providers.dart';
import 'package:kola/core/providers/document_engine_providers.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:kola/document/fidelity/document_fidelity_renderer.dart';
import 'package:kola/document/model/document_models.dart';
import 'package:kola/document/registry/document_adapter.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.documentId, super.key});

  final String documentId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _flowMode = false;
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<KolaDocument?> document = ref.watch(
      documentProvider(widget.documentId),
    );

    return document.when(
      data: (KolaDocument? value) {
        if (value == null) {
          return _ReaderMessage(
            title: 'Document not found',
            message: 'This library item no longer exists.',
            onBack: () => context.pop(),
          );
        }
        return _buildReader(context, value);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => _ReaderMessage(
        title: 'Could not load document',
        message: error.toString(),
        onBack: () => context.pop(),
      ),
    );
  }

  Widget _buildReader(BuildContext context, KolaDocument document) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final FormatCapabilities capabilities =
        ref.watch(formatRegistryProvider).capabilitiesFor(document.format) ??
        const FormatCapabilities();
    final DocumentFidelityRenderer? fidelityRenderer = ref
        .watch(fidelityRendererRegistryProvider)
        .rendererFor(document.format);

    final Widget surface = _flowMode
        ? const _FlowUnavailable()
        : fidelityRenderer?.build(context, document) ??
              _FidelityUnavailable(document: document);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(
                  () => _controlsVisible = !_controlsVisible,
                ),
                child: surface,
              ),
            ),
            AnimatedSlide(
              duration: KolaMotion.standard,
              offset: _controlsVisible ? Offset.zero : const Offset(0, -1.2),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: KolaMotion.quick,
                opacity: _controlsVisible ? 1 : 0,
                child: _ReaderTopBar(
                  document: document,
                  flowMode: _flowMode,
                  flowAvailable: capabilities.flowMode,
                  onBack: () => context.pop(),
                  onModeChanged: (bool value) {
                    if (value && !capabilities.flowMode) return;
                    setState(() => _flowMode = value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.document,
    required this.flowMode,
    required this.flowAvailable,
    required this.onBack,
    required this.onModeChanged,
  });

  final KolaDocument document;
  final bool flowMode;
  final bool flowAvailable;
  final VoidCallback onBack;
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
          child: Row(
            children: <Widget>[
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
                    tooltip: flowAvailable ? 'Flow' : 'Flow not available yet',
                  ),
                ],
                selected: <bool>{flowMode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<bool> selection) =>
                    onModeChanged(selection.first),
              ),
              IconButton(
                onPressed: null,
                tooltip: 'Search will be enabled after PDF text indexing',
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
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
      message:
          'Kola will enable Flow only after source-mapped semantic extraction is implemented for this format.',
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
