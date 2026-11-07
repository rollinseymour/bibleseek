import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/reader_palette.dart';
import '../wordstudy/lexicon.dart';
import '../wordstudy/morphology.dart';
import '../wordstudy/strongs_card.dart';

const _strongsBlue = Color(0xFF6EA8FE);

/// A verse's original-language words as tappable blocks, in reading order.
/// Blocks run left to right so they line up with the verse above; each Hebrew
/// word still renders right to left inside its block.
class InterlinearWords extends StatelessWidget {
  const InterlinearWords({
    super.key,
    required this.words,
    required this.palette,
    required this.fontSize,
  });
  final List<InterlinearWord> words;
  final ReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final w in words)
          _Block(
            palette: palette,
            onTap: () => showInterlinearWord(context, w),
            lines: [
              Text(
                w.original,
                style: TextStyle(
                  fontSize: fontSize * 0.92,
                  color: palette.text,
                ),
              ),
              if (w.translit.isNotEmpty)
                Text(
                  w.translit,
                  style: TextStyle(
                    fontSize: fontSize * 0.58,
                    fontStyle: FontStyle.italic,
                    color: palette.accent,
                  ),
                ),
              Text(
                w.english,
                style: TextStyle(
                  fontSize: fontSize * 0.62,
                  color: palette.text.withValues(alpha: 0.85),
                ),
              ),
              // The contextual English can expand to a phrase; show the one-word sense too.
              if (w.gloss.isNotEmpty &&
                  w.gloss.toLowerCase() != w.english.toLowerCase())
                Text(
                  w.gloss,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize * 0.55,
                    fontStyle: FontStyle.italic,
                    color: palette.text.withValues(alpha: 0.5),
                  ),
                ),
              _codes(w.strongs, w.grammar),
            ],
          ),
      ],
    ),
  );

  Widget _codes(String strongs, String grammar) => Wrap(
    spacing: 5,
    children: [
      if (strongs.isNotEmpty)
        Text(
          strongs,
          style: TextStyle(
            fontSize: fontSize * 0.52,
            fontWeight: FontWeight.w600,
            color: _strongsBlue,
          ),
        ),
      if (grammar.isNotEmpty)
        Text(
          grammar,
          maxLines: 1,
          style: TextStyle(
            fontSize: fontSize * 0.5,
            color: palette.text.withValues(alpha: 0.5),
          ),
        ),
    ],
  );
}

/// The KJV words in English order, each with the Greek or Hebrew behind it
/// (matched by Strong's number). Supplied words show in brackets.
class ReverseWords extends StatelessWidget {
  const ReverseWords({
    super.key,
    required this.words,
    required this.originals,
    required this.palette,
    required this.fontSize,
  });
  final List<ReverseWord> words;
  final List<InterlinearWord> originals;
  final ReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final w in words)
          Builder(
            builder: (context) {
              final orig = w.strongs.isEmpty
                  ? null
                  : originals.where((o) => o.strongs == w.strongs).firstOrNull;
              final dim = w.supplied || w.english.isEmpty;
              return _Block(
                palette: palette,
                faint: w.supplied,
                onTap: orig == null
                    ? null
                    : () => showInterlinearWord(context, orig),
                lines: [
                  Text(
                    w.supplied
                        ? '[${w.english}]'
                        : (w.english.isEmpty ? '—' : w.english),
                    style: TextStyle(
                      fontSize: fontSize * 0.72,
                      fontStyle: w.supplied ? FontStyle.italic : null,
                      color: palette.text.withValues(alpha: dim ? 0.45 : 1),
                    ),
                  ),
                  if (orig != null && orig.original.isNotEmpty) ...[
                    Text(
                      orig.original,
                      style: TextStyle(
                        fontSize: fontSize * 0.68,
                        color: palette.text.withValues(alpha: 0.9),
                      ),
                    ),
                    if (orig.translit.isNotEmpty)
                      Text(
                        orig.translit,
                        style: TextStyle(
                          fontSize: fontSize * 0.54,
                          fontStyle: FontStyle.italic,
                          color: palette.accent,
                        ),
                      ),
                  ],
                  Wrap(
                    spacing: 5,
                    children: [
                      if (w.strongs.isNotEmpty)
                        Text(
                          w.strongs,
                          style: TextStyle(
                            fontSize: fontSize * 0.52,
                            fontWeight: FontWeight.w600,
                            color: _strongsBlue,
                          ),
                        ),
                      if (orig != null && orig.grammar.isNotEmpty)
                        Text(
                          orig.grammar,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: fontSize * 0.5,
                            color: palette.text.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({
    required this.palette,
    required this.lines,
    this.onTap,
    this.faint = false,
  });
  final ReaderPalette palette;
  final List<Widget> lines;
  final VoidCallback? onTap;
  final bool faint;

  @override
  Widget build(BuildContext context) => Material(
    color: palette.text.withValues(alpha: faint ? 0.03 : 0.06),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      ),
    ),
  );
}

/// A tapped interlinear word: the word, its parsing in plain English, and its
/// full Strong's entry.
Future<void> showInterlinearWord(BuildContext context, InterlinearWord word) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: WordStudyReady(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            final muted = scheme.onSurface.withValues(alpha: 0.55);
            final hasEntry =
                word.strongs.isNotEmpty &&
                context.read<WordStudyData>().entry(word.strongs) != null;
            Widget box(String label, List<Widget> children) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...children,
                ],
              ),
            );
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.strongs.isEmpty ? 'Word' : word.strongs,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      Text(
                        word.original,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (word.translit.isNotEmpty)
                        Text(
                          word.translit,
                          style: TextStyle(
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            color: scheme.primary,
                          ),
                        ),
                      Text(
                        word.english,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (word.grammar.isNotEmpty) ...[
                        box('PARSING', [
                          Text(
                            Morphology.describe(word.grammar),
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            word.grammar,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      if (hasEntry)
                        StrongsCard(code: word.strongs)
                      else if (word.gloss.isNotEmpty)
                        box('DICTIONARY FORM', [
                          Text(
                            word.gloss,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
