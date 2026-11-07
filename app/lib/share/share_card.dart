import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_store.dart';
import '../design/reader_fonts.dart';
import '../web/browser.dart';
import '../widgets/copy.dart';
import '../widgets/mouse_drag_scroll.dart';

/// One run of card text: plain, words of Jesus, or a small verse-number marker.
class ShareRun {
  const ShareRun(
    this.text, {
    this.wordsOfJesus = false,
    this.isVerseNumber = false,
  });
  final String text;
  final bool wordsOfJesus;
  final bool isVerseNumber;

  static String plainText(List<ShareRun> runs) {
    final buf = StringBuffer();
    var last = '';
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      if (last.isNotEmpty && !last.endsWith(' ') && !r.text.startsWith(' ')) {
        buf.write(' ');
      }
      buf.write(r.text);
      last = r.text;
    }
    return buf.toString();
  }

  /// Runs for a passage, loaded with red letter so words of Jesus are marked
  /// whatever the reader's setting. Gaps get an ellipsis; multi-verse cards
  /// number each verse.
  static Future<List<ShareRun>> forPassage(
    BibleStore store,
    String version,
    String book,
    int chapter,
    List<int> verses,
  ) async {
    final loaded = {
      for (final v in await store.chapter(
        version,
        book,
        chapter,
        redLetter: true,
      ))
        v.number: v,
    };
    final runs = <ShareRun>[];
    int? prev;
    final numbers = verses.length > 1;
    for (final n in [...verses]..sort()) {
      final v = loaded[n];
      if (v == null) continue;
      if (prev != null && n > prev + 1 && runs.isNotEmpty) {
        runs.add(const ShareRun(' … '));
      }
      prev = n;
      if (numbers) runs.add(ShareRun('$n', isVerseNumber: true));
      for (final p in v.parts) {
        final text = p.text.replaceAll('¶ ', '').replaceAll('¶', '');
        if (text.isNotEmpty) {
          runs.add(ShareRun(text, wordsOfJesus: p.wordsOfJesus && !p.isNote));
        }
      }
    }
    return runs;
  }
}

/// One passage on a card: its reference and text runs.
class SharePassage {
  SharePassage(this.reference, this.runs) : id = UniqueKey();
  final Key id;
  final String reference;
  final List<ShareRun> runs;

  String get plainText => ShareRun.plainText(runs);
  bool get hasRedLetter => runs.any((r) => r.wordsOfJesus);
}

class ShareCardTheme {
  const ShareCardTheme(
    this.label,
    this.gradient,
    this.foreground,
    this.accent, {
    this.texture,
  });
  final String label;
  final List<Color> gradient;
  final Color foreground;
  final Color accent;

  /// A cover-fit image painted instead of the gradient.
  final String? texture;

  bool get isLight => gradient.first.computeLuminance() > 0.35;

  static const all = [
    ShareCardTheme(
      'Parchment',
      [Color(0xFFF6EDD8), Color(0xFFE8D9B6)],
      Color(0xFF2E1C0C),
      Color(0xFF7A5A2D),
    ),
    ShareCardTheme(
      'Slate',
      [Color(0xFF1F2630), Color(0xFF2B333F)],
      Color(0xFFE7ECF2),
      Color(0xFF7DB6FF),
    ),
    ShareCardTheme(
      'Sage',
      [Color(0xFFE7F1EA), Color(0xFFC9DCD0)],
      Color(0xFF1F3A2A),
      Color(0xFF3F8761),
    ),
    ShareCardTheme(
      'Gold',
      [Color(0xFFFFF6E0), Color(0xFFE9CB81)],
      Color(0xFF3B2C0C),
      Color(0xFF9C7715),
    ),
    ShareCardTheme(
      'Midnight',
      [Color(0xFF0B1020), Color(0xFF1A2238)],
      Color(0xFFEAEEF7),
      Color(0xFFD4AF37),
    ),
    ShareCardTheme(
      'Rose',
      [Color(0xFFF7E3E3), Color(0xFFE9C4CB)],
      Color(0xFF5A2A33),
      Color(0xFFB05C73),
    ),
    ShareCardTheme(
      'Ocean',
      [Color(0xFFD7EFF2), Color(0xFFA9D6DE)],
      Color(0xFF103A45),
      Color(0xFF1F8FA8),
    ),
    ShareCardTheme(
      'Linen',
      [Color(0xFFFAF8F4), Color(0xFFEDE8DF)],
      Color(0xFF2C2A26),
      Color(0xFF8A7E6A),
    ),
    ShareCardTheme(
      'Sunrise',
      [Color(0xFFFFE7C7), Color(0xFFF6C58B)],
      Color(0xFF4A2D12),
      Color(0xFFD08A2C),
    ),
    ShareCardTheme(
      'Paper',
      [Color(0xFFF6EDD8), Color(0xFFE8D9B6)],
      Color(0xFF2E1C0C),
      Color(0xFF7A5A2D),
      texture: 'assets/images/parchment_paper.jpg',
    ),
  ];
}

enum ShareCardLayout {
  classic,
  centered,
  quote,
  accent,
  header,
  framed,
  scroll,
}

extension on ShareCardLayout {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

/// A card's styling, carried through "Add other verses" so it comes back the same.
class ShareCardStyle {
  const ShareCardStyle(this.theme, this.layout, this.redLetter);
  final ShareCardTheme theme;
  final ShareCardLayout layout;
  final bool redLetter;
}

/// A 1080×1080 verse card (the Scroll layout grows with the text), the verse
/// size stepping down with length and the whole block scaling to fit.
class ShareCardView extends StatelessWidget {
  const ShareCardView({
    super.key,
    required this.passages,
    required this.theme,
    required this.layout,
    required this.redLetter,
  });
  final List<SharePassage> passages;
  final ShareCardTheme theme;
  final ShareCardLayout layout;
  final bool redLetter;

  static const side = 1080.0;

  double get _bodySize {
    final count =
        passages.fold<int>(0, (n, p) => n + p.plainText.length + 30) - 30;
    return switch (count) {
      < 150 => 48,
      < 250 => 40,
      < 360 => 34,
      < 500 => 30,
      < 750 => 26,
      < 1100 => 22,
      < 1600 => 19,
      _ => 17,
    };
  }

  Color get _red =>
      theme.isLight ? const Color(0xFFB3261E) : const Color(0xFFFF5A5A);

  TextStyle _serif(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => readerTextStyle(
    'New York',
    fontSize: size,
    fontWeight: weight,
    color: color ?? theme.foreground,
    height: 1.35,
  );

  Widget _verse(SharePassage p, TextAlign align) {
    final size = _bodySize;
    final spans = <InlineSpan>[const TextSpan(text: '“')];
    var last = '';
    for (final r in p.runs) {
      if (r.text.isEmpty) continue;
      if (last.isNotEmpty && !last.endsWith(' ') && !r.text.startsWith(' ')) {
        spans.add(const TextSpan(text: ' '));
      }
      if (r.isVerseNumber) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, -size * 0.3),
              child: Padding(
                padding: EdgeInsets.only(right: size * 0.15),
                child: Text(
                  r.text,
                  style: _serif(
                    size * 0.55,
                    weight: FontWeight.w700,
                    color: theme.accent.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: r.text,
            style: redLetter && r.wordsOfJesus ? TextStyle(color: _red) : null,
          ),
        );
      }
      last = r.text;
    }
    spans.add(const TextSpan(text: '”'));
    return Text.rich(
      TextSpan(children: spans),
      textAlign: align,
      style: _serif(size),
    );
  }

  Widget _ref(
    SharePassage p, {
    double size = 34,
    FontWeight weight = FontWeight.w600,
  }) => Text(
    p.reference,
    style: _serif(size, weight: weight, color: theme.accent),
  );

  Widget _passages(
    CrossAxisAlignment cross,
    TextAlign align, {
    bool divider = false,
  }) => Column(
    crossAxisAlignment: cross,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, p) in passages.indexed) ...[
        if (i > 0) const SizedBox(height: 44),
        _verse(p, align),
        const SizedBox(height: 24),
        if (divider) ...[
          Container(
            width: 90,
            height: 3,
            color: theme.accent.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
        ],
        _ref(p),
      ],
    ],
  );

  /// Content is laid out at the card's inner width, then scaled down if it
  /// runs taller than the square.
  Widget _fit(Widget child, double width) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(width: width, child: child),
    ),
  );

  Widget _background() => theme.texture != null
      ? Image.asset(
          theme.texture!,
          fit: BoxFit.cover,
          width: side,
          height: double.infinity,
        )
      : DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    if (layout == ShareCardLayout.scroll) {
      Widget rule() => Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              color: theme.accent.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              color: theme.accent.withValues(alpha: 0.35),
            ),
          ),
        ],
      );
      return SizedBox(
        width: side,
        child: Stack(
          children: [
            Positioned.fill(child: _background()),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 84,
                  vertical: 80,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    rule(),
                    for (final p in passages) ...[
                      const SizedBox(height: 30),
                      _verse(p, TextAlign.center),
                      const SizedBox(height: 30),
                      _ref(p),
                    ],
                    const SizedBox(height: 30),
                    rule(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    const inner = side - 160;
    final Widget content = switch (layout) {
      ShareCardLayout.classic => _fit(
        _passages(CrossAxisAlignment.center, TextAlign.center),
        inner,
      ),
      ShareCardLayout.centered => _fit(
        _passages(CrossAxisAlignment.center, TextAlign.center, divider: true),
        inner,
      ),
      ShareCardLayout.quote => _fit(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 110,
              child: Text(
                '“',
                style: _serif(
                  180,
                  weight: FontWeight.w700,
                  color: theme.accent.withValues(alpha: 0.5),
                ).copyWith(height: 1),
              ),
            ),
            _passages(CrossAxisAlignment.start, TextAlign.left),
          ],
        ),
        inner,
      ),
      ShareCardLayout.accent => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 10,
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: _fit(
              _passages(CrossAxisAlignment.start, TextAlign.left),
              inner - 38,
            ),
          ),
        ],
      ),
      ShareCardLayout.header => _fit(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, p) in passages.indexed) ...[
              if (i > 0) const SizedBox(height: 44),
              _ref(p, size: 44, weight: FontWeight.w700),
              const SizedBox(height: 28),
              Container(height: 3, color: theme.accent.withValues(alpha: 0.4)),
              const SizedBox(height: 28),
              _verse(p, TextAlign.left),
            ],
          ],
        ),
        inner,
      ),
      ShareCardLayout.framed => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.accent.withValues(alpha: theme.isLight ? 1 : 0.55),
            width: 4,
          ),
        ),
        padding: const EdgeInsets.all(44),
        child: _fit(
          _passages(CrossAxisAlignment.center, TextAlign.center),
          inner - 96,
        ),
      ),
      ShareCardLayout.scroll => const SizedBox.shrink(),
    };
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        children: [
          Positioned.fill(child: _background()),
          Positioned.fill(
            child: Padding(padding: const EdgeInsets.all(80), child: content),
          ),
        ],
      ),
    );
  }
}

/// Preview the card, flip through themes and layouts, then share or save it
/// as an image, or share the text.
Future<void> showShareCard(
  BuildContext context,
  List<SharePassage> passages, {
  ShareCardStyle? style,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.94,
    child: _ShareSheet(passages, style),
  ),
);

/// The reader's selection, a topic card or the Verse of the Day as a card.
Future<void> shareVerses(
  BuildContext context, {
  required String reference,
  required String version,
  required String book,
  required int chapter,
  required List<int> verses,
}) async {
  final runs = await ShareRun.forPassage(
    context.read<BibleStore>(),
    version,
    book,
    chapter,
    verses,
  );
  if (!context.mounted || runs.isEmpty) return;
  await showShareCard(context, [SharePassage(reference, runs)]);
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet(this.initial, this.style);
  final List<SharePassage> initial;
  final ShareCardStyle? style;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _card = GlobalKey();
  late final List<SharePassage> _passages = [...widget.initial];
  late ShareCardTheme _theme = widget.style?.theme ?? ShareCardTheme.all.first;
  late ShareCardLayout _layout =
      widget.style?.layout ?? ShareCardLayout.classic;
  late bool _redLetter =
      widget.style?.redLetter ?? _passages.any((p) => p.hasRedLetter);
  bool _removing = false;
  bool _busy = false;

  String get _text =>
      _passages.map((p) => '“${p.plainText}”\n— ${p.reference}').join('\n\n');
  String get _filename =>
      'BibleSeek-${_passages.first.reference.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/parchment_paper.jpg'),
      context,
    );
  }

  Future<List<int>?> _png() async {
    final boundary = _card.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _withImage(Future<void> Function(List<int> bytes) action) async {
    setState(() => _busy = true);
    try {
      final bytes = await _png();
      if (bytes != null) await action(bytes);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() => _withImage((bytes) async {
    if (canShareFile(_filename, bytes, 'image/png')) {
      await shareFile(_filename, bytes, 'image/png');
    } else {
      downloadBytes(_filename, bytes, 'image/png');
    }
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Share',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                    maxHeight: 520,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FittedBox(
                      child: RepaintBoundary(
                        key: _card,
                        child: ShareCardView(
                          passages: _passages,
                          theme: _theme,
                          layout: _layout,
                          redLetter: _redLetter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: MouseDragScroll(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in ShareCardTheme.all)
                        Tooltip(
                          message: t.label,
                          child: GestureDetector(
                            onTap: () => setState(() => _theme = t),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10, top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: t.gradient,
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                image: t.texture == null
                                    ? null
                                    : DecorationImage(
                                        image: AssetImage(t.texture!),
                                        fit: BoxFit.cover,
                                      ),
                                border: Border.all(
                                  color: t == _theme
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(
                                          alpha: 0.15,
                                        ),
                                  width: t == _theme ? 3 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in ShareCardLayout.values)
                    ChoiceChip(
                      label: Text(l.label),
                      selected: l == _layout,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _layout = l),
                    ),
                ],
              ),
              if (_passages.any((p) => p.hasRedLetter))
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Red-letter (words of Jesus)'),
                  value: _redLetter,
                  onChanged: (v) => setState(() => _redLetter = v),
                ),
              const SizedBox(height: 8),
              if (_busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _shareImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Share image'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _withImage(
                        (bytes) async =>
                            downloadBytes(_filename, bytes, 'image/png'),
                      ),
                icon: const Icon(Icons.download),
                label: const Text('Save image'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => canShareNatively
                    ? shareText(_text)
                    : copyWithFeedback(context, _text),
                icon: const Icon(Icons.format_quote),
                label: Text(
                  canShareNatively ? 'Share as text' : 'Copy as text',
                ),
              ),
              if (_removing)
                for (final p in _passages)
                  ListTile(
                    title: Text(p.reference),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: _passages.length == 1
                          ? null
                          : () => setState(() {
                              _passages.remove(p);
                              if (_passages.length <= 1) _removing = false;
                            }),
                    ),
                  ),
              if (_passages.length > 1) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _removing = !_removing),
                  icon: Icon(
                    _removing
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                  label: Text(
                    _removing ? 'Done removing' : 'Remove select verses',
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AppModel>().beginSharePick(
                    _passages,
                    ShareCardStyle(_theme, _layout, _redLetter),
                  );
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add other verses'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
