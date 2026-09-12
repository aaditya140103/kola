import 'package:flutter/material.dart';

class SearchSnippetText extends StatelessWidget {
  const SearchSnippetText(
    this.snippet, {
    super.key,
    this.maxLines = 3,
  });

  final String snippet;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle highlighted = base.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
    );

    return Text.rich(
      TextSpan(children: _spans(snippet, base, highlighted)),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  static List<InlineSpan> _spans(
    String value,
    TextStyle base,
    TextStyle highlighted,
  ) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    while (cursor < value.length) {
      final int start = value.indexOf('[[', cursor);
      if (start < 0) {
        spans.add(TextSpan(text: value.substring(cursor), style: base));
        break;
      }
      if (start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, start), style: base));
      }
      final int end = value.indexOf(']]', start + 2);
      if (end < 0) {
        spans.add(TextSpan(text: value.substring(start + 2), style: highlighted));
        break;
      }
      spans.add(
        TextSpan(
          text: value.substring(start + 2, end),
          style: highlighted,
        ),
      );
      cursor = end + 2;
    }
    if (spans.isEmpty) spans.add(TextSpan(text: value, style: base));
    return spans;
  }
}
