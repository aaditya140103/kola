import 'package:flutter/material.dart';
import 'package:kola/design_system/tokens/kola_tokens.dart';
import 'package:pdfrx/pdfrx.dart';

final class PdfThumbnailSheet extends StatelessWidget {
  const PdfThumbnailSheet({
    required this.document,
    required this.currentPage,
    super.key,
  });

  final PdfDocument document;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KolaSpacing.lg,
              KolaSpacing.sm,
              KolaSpacing.lg,
              KolaSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.grid_view_rounded),
                const SizedBox(width: KolaSpacing.sm),
                Expanded(
                  child: Text(
                    'Pages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${document.pages.length} pages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(KolaSpacing.md),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisExtent: 230,
                crossAxisSpacing: KolaSpacing.sm,
                mainAxisSpacing: KolaSpacing.sm,
              ),
              itemCount: document.pages.length,
              itemBuilder: (BuildContext context, int index) {
                final int pageNumber = index + 1;
                return _PdfThumbnailTile(
                  document: document,
                  pageNumber: pageNumber,
                  selected: pageNumber == currentPage,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfThumbnailTile extends StatelessWidget {
  const _PdfThumbnailTile({
    required this.document,
    required this.pageNumber,
    required this.selected,
  });

  final PdfDocument document;
  final int pageNumber;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final PdfPage page = document.pages[pageNumber - 1];
    final Color borderColor = selected ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Page $pageNumber thumbnail',
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: KolaRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('pdf-thumbnail-$pageNumber'),
          onTap: () => Navigator.of(context).pop(pageNumber),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: selected ? 2 : 1,
              ),
              borderRadius: KolaRadius.md,
            ),
            child: Padding(
              padding: const EdgeInsets.all(KolaSpacing.xs),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: page.width / page.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: scheme.outlineVariant),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PdfPageView(
                            document: document,
                            pageNumber: pageNumber,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: KolaSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (selected) ...<Widget>[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: KolaSpacing.xxs),
                      ],
                      Text(
                        'Page $pageNumber',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
