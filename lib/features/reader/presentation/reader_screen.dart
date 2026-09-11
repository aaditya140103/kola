import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.documentId, super.key});

  final String documentId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _flowMode = true;
  bool _controlsVisible = true;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _controlsVisible = !_controlsVisible),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: _flowMode
                        ? _FlowReadingSurface(documentId: widget.documentId)
                        : const _FidelityPlaceholder(),
                  ),
                ),
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
                  flowMode: _flowMode,
                  onBack: () => context.pop(),
                  onModeChanged: (bool value) => setState(() => _flowMode = value),
                ),
              ),
            ),
            Positioned(
              left: KolaSpacing.md,
              right: KolaSpacing.md,
              bottom: KolaSpacing.md,
              child: AnimatedSlide(
                duration: KolaMotion.standard,
                offset: _controlsVisible ? Offset.zero : const Offset(0, 1.5),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: KolaMotion.quick,
                  opacity: _controlsVisible ? 1 : 0,
                  child: const _ReaderBottomBar(),
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
    required this.flowMode,
    required this.onBack,
    required this.onModeChanged,
  });

  final bool flowMode;
  final VoidCallback onBack;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(KolaSpacing.md),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: KolaRadius.pill,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolaSpacing.xs, vertical: KolaSpacing.xxs),
          child: Row(
            children: <Widget>[
              IconButton(onPressed: onBack, tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: KolaSpacing.xs),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('The Design of Everyday Things', maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Chapter 3 · Knowledge in the head and world', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: false, icon: Icon(Icons.description_rounded), tooltip: 'Fidelity'),
                  ButtonSegment<bool>(value: true, icon: Icon(Icons.auto_stories_rounded), tooltip: 'Flow'),
                ],
                selected: <bool>{flowMode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<bool> selection) => onModeChanged(selection.first),
              ),
              IconButton(onPressed: () {}, tooltip: 'Search document', icon: const Icon(Icons.search_rounded)),
              IconButton(onPressed: () {}, tooltip: 'Appearance', icon: const Icon(Icons.format_size_rounded)),
              IconButton(onPressed: () {}, tooltip: 'More', icon: const Icon(Icons.more_horiz_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowReadingSurface extends StatelessWidget {
  const _FlowReadingSurface({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 108, 24, 108),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF191D1C) : const Color(0xFFF8F4EA),
          borderRadius: KolaRadius.lg,
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 12),
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.24 : 0.10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('CHAPTER 3', style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.6)),
                const SizedBox(height: KolaSpacing.md),
                Text(
                  'Knowledge in the Head and in the World',
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.12),
                ),
                const SizedBox(height: KolaSpacing.xl),
                const Text(
                  'This is Kola’s first Flow Mode shell. The final renderer will not display a converted copy of the document. It will render source-mapped semantic blocks from the Kola Document Graph so selections, highlights, progress, and navigation can resolve back to the original file.',
                ),
                const SizedBox(height: KolaSpacing.lg),
                const Text(
                  'The reading surface is deliberately quieter than the surrounding application chrome. Typography, content width, line spacing, and background will become reader-controlled settings while the source document remains unchanged.',
                ),
                const SizedBox(height: KolaSpacing.lg),
                _PrototypeHighlight(
                  child: const Text(
                    'Annotations created here will eventually share the same durable source anchor as annotations created in Fidelity View.',
                  ),
                ),
                const SizedBox(height: KolaSpacing.lg),
                const Text(
                  'Tap anywhere outside the controls to hide the reader chrome. This interaction is only a prototype; platform-specific behavior and accessibility validation will be handled by the adaptive design system.',
                ),
                const SizedBox(height: KolaSpacing.xl),
                Text('Prototype document id: $documentId', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrototypeHighlight extends StatelessWidget {
  const _PrototypeHighlight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: KolaRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KolaSpacing.xs, vertical: KolaSpacing.xxs),
        child: child,
      ),
    );
  }
}

class _FidelityPlaceholder extends StatelessWidget {
  const _FidelityPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 108, 24, 108),
      child: AspectRatio(
        aspectRatio: 0.707,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: KolaRadius.sm,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.description_rounded, size: 56),
                SizedBox(height: KolaSpacing.md),
                Text('Fidelity renderer plugs in here'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Material(
          color: scheme.surface.withValues(alpha: 0.94),
          borderRadius: KolaRadius.pill,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolaSpacing.md, vertical: KolaSpacing.xs),
            child: Row(
              children: <Widget>[
                const Text('68%'),
                const SizedBox(width: KolaSpacing.md),
                const Expanded(child: LinearProgressIndicator(value: 0.68, minHeight: 5)),
                const SizedBox(width: KolaSpacing.md),
                IconButton(onPressed: () {}, tooltip: 'Bookmark', icon: const Icon(Icons.bookmark_border_rounded)),
                IconButton(onPressed: () {}, tooltip: 'Annotate', icon: const Icon(Icons.edit_rounded)),
                IconButton(onPressed: () {}, tooltip: 'Contents', icon: const Icon(Icons.list_alt_rounded)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
