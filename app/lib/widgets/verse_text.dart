import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bible/models.dart';
import '../design/reader_fonts.dart';
import '../settings/settings_model.dart';

/// A verse in lists and cards: the reader font, words of Jesus in red when
/// red letter is on, editorial notes muted and italic.
class VerseText extends StatelessWidget {
  const VerseText(this.verse, {super.key, this.maxLines, this.fontSize = 16});

  final Verse? verse;
  final int? maxLines;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final red = dark ? const Color(0xFFFF9E95) : const Color(0xFF701A1A);
    final base = readerTextStyle(
      settings.readerFont,
      fontSize: fontSize,
      height: 1.5,
      color: scheme.onSurface,
    );
    final v = verse;
    if (v == null) return Text('—', style: base);
    final spans = <TextSpan>[];
    var last = '';
    for (final part in v.parts) {
      if (part.text.isEmpty) continue;
      if (last.isNotEmpty &&
          !last.endsWith(' ') &&
          !part.text.startsWith(' ')) {
        spans.add(const TextSpan(text: ' '));
      }
      spans.add(
        TextSpan(
          text: part.text,
          style: part.isNote
              ? TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                )
              : (part.wordsOfJesus && settings.redLetter)
              ? TextStyle(color: red)
              : null,
        ),
      );
      last = part.text;
    }
    return Text.rich(
      TextSpan(children: spans),
      style: base,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
