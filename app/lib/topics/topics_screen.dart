import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../design/reader_fonts.dart';
import '../reader/reader_model.dart';
import '../settings/settings_model.dart';
import '../web/browser.dart';
import '../widgets/copy.dart';
import '../widgets/mouse_drag_scroll.dart';
import 'topics.dart';

/// Waits for the topic catalog, with a retry if it can't be fetched.
class _TopicsLoader extends StatelessWidget {
  const _TopicsLoader({required this.builder});
  final Widget Function(BuildContext, List<Topic>) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: TopicsCatalog.load(context.read<BibleStore>()),
    builder: (context, snap) {
      if (snap.hasData) return builder(context, snap.data!);
      if (snap.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Couldn’t load topics.'),
              TextButton(
                onPressed: () => (context as Element).markNeedsBuild(),
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    },
  );
}

void _openTopic(BuildContext context, Topic t, List<Topic> all) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailScreen(topic: t, allTopics: all),
      ),
    );

/// Today's topic, then a swipeable rail of topic cards per category.
/// Searching replaces the rails with a ranked list.
class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: _TopicsLoader(
        builder: (context, topics) {
          final query = _search.text.trim();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search topics…',
                        isDense: true,
                        filled: true,
                        fillColor: scheme.onSurface.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => setState(_search.clear),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    ..._results(context, topics, query)
                  else ...[
                    if (TopicsCatalog.topicOfDay(topics) case final today?)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _hero(context, today, topics),
                      ),
                    for (final g in TopicsCatalog.grouped(topics))
                      _rail(context, g.category, g.topics, topics),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _results(
    BuildContext context,
    List<Topic> topics,
    String query,
  ) {
    final hits = TopicsCatalog.search(topics, query);
    if (hits.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text('No topics match “$query”.')),
        ),
      ];
    }
    return [
      for (final t in hits)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TopicRow(
            topic: t,
            showCategory: true,
            onTap: () => _openTopic(context, t, topics),
          ),
        ),
    ];
  }

  Widget _hero(BuildContext context, Topic t, List<Topic> all) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openTopic(context, t, all),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S TOPIC",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                t.cleanTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (t.summary.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  t.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${t.category} · ${t.verseCountLabel}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rail(
    BuildContext context,
    String category,
    List<Topic> items,
    List<Topic> all,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final tint = TopicsCatalog.tint(category);
    final muted = scheme.onSurface.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CategoryTopicsScreen(
                  category: category,
                  topics: items,
                  allTopics: all,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Text(
                    'All ${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: MouseDragScroll(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, i) =>
                    _railCard(context, items[i], tint, all),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railCard(BuildContext context, Topic t, Color tint, List<Topic> all) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 152,
      child: Material(
        color: scheme.onSurface.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tint.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openTopic(context, t, all),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.cleanTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    t.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Text(
                  t.verseCountLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tint,
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

/// One topic as a full-width row: title, summary, verse count.
class TopicRow extends StatelessWidget {
  const TopicRow({
    super.key,
    required this.topic,
    required this.showCategory,
    required this.onTap,
  });
  final Topic topic;
  final bool showCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                topic.cleanTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (topic.summary.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  topic.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                showCategory
                    ? '${topic.category} · ${topic.verseCountLabel}'
                    : topic.verseCountLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: TopicsCatalog.tint(topic.category),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A category's topics, alphabetical.
class CategoryTopicsScreen extends StatelessWidget {
  const CategoryTopicsScreen({
    super.key,
    required this.category,
    required this.topics,
    required this.allTopics,
  });
  final String category;
  final List<Topic> topics;
  final List<Topic> allTopics;

  @override
  Widget build(BuildContext context) {
    final sorted = [...topics]
      ..sort(
        (a, b) =>
            a.cleanTitle.toLowerCase().compareTo(b.cleanTitle.toLowerCase()),
      );
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => TopicRow(
              topic: sorted[i],
              showCategory: false,
              onTap: () => _openTopic(context, sorted[i], allTopics),
            ),
          ),
        ),
      ),
    );
  }
}

class _Quote {
  const _Quote(this.reference, this.verses, this.target);
  final String reference;

  /// Number 0 marks a placeholder message instead of a verse.
  final List<({int number, String text})> verses;
  final ReaderTarget? target;
  bool get hasVerses => verses.any((v) => v.number > 0);
}

/// A topic's summary and every scripture card (favorite, copy, share; tap to
/// read), in a translation the pill cycles through, then related topics.
class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.allTopics,
  });
  final Topic topic;
  final List<Topic> allTopics;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late String _version;
  List<_Quote>? _quotes;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _version = ReadingPosition.load(context.read())?.version ?? 'KJV';
    if (!BibleStore.versions.contains(_version)) _version = 'KJV';
    _load();
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() => _quotes = null);
    final library = context.read<BibleLibrary>();
    final store = context.read<BibleStore>();
    final out = <_Quote>[];
    for (final ref in widget.topic.quotes) {
      final r = library.parseRange(ref);
      if (r == null) {
        out.add(
          _Quote(ref, const [
            (number: 0, text: 'Invalid reference format.'),
          ], null),
        );
        continue;
      }
      List<({int number, String text})> verses;
      try {
        final chapter = await store.chapter(
          _version,
          r.book.id,
          r.chapter,
          redLetter: false,
        );
        verses = [
          for (final v in chapter)
            if (v.number >= r.start &&
                v.number <= r.end &&
                v.plainText.isNotEmpty)
              (number: v.number, text: v.plainText),
        ];
      } catch (_) {
        verses = const [];
      }
      out.add(
        _Quote(
          ref,
          verses.isEmpty
              ? const [(number: 0, text: 'Verse not found.')]
              : verses,
          ReaderTarget(
            bookCode: r.book.id,
            chapter: r.chapter,
            verse: r.start,
            endVerse: r.end > r.start ? r.end : null,
            version: _version,
          ),
        ),
      );
    }
    if (mounted && token == _token) setState(() => _quotes = out);
  }

  String _plain(_Quote q) =>
      q.verses.map((v) => v.text).where((t) => t.isNotEmpty).join(' ');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final related = TopicsCatalog.related(widget.topic, widget.allTopics);
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.cleanTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                widget.topic.cleanTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message:
                      '${BibleStore.versionName(_version)} — tap to switch',
                  child: Material(
                    color: scheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _version = BibleStore.nextVersion(_version);
                        _load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _version,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.swap_horiz,
                              size: 13,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.topic.summary,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Relevant Scripture(s)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (_quotes == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final q in _quotes!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _card(q),
                  ),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Related Topics',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in related)
                      ActionChip(
                        label: Text(t.cleanTitle),
                        labelStyle: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        backgroundColor: scheme.primary.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                        shape: const StadiumBorder(),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TopicDetailScreen(
                              topic: t,
                              allTopics: widget.allTopics,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(_Quote q) {
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<AnnotationStore>();
    final settings = context.read<SettingsModel>();
    final t = q.target;
    final favorite =
        t != null &&
        store.isFavorite(t.bookCode, t.chapter, t.verse!, t.endVerse);
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Material(
      color: scheme.onSurface.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: t == null ? null : () => context.read<AppModel>().open(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (final (i, v) in q.verses.indexed) ...[
                        if (i > 0) const TextSpan(text: '\n'),
                        if (v.number > 0)
                          TextSpan(
                            text: '${v.number} ',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        TextSpan(text: v.text),
                      ],
                    ],
                  ),
                  style: readerTextStyle(
                    settings.readerFont,
                    fontSize: 15,
                    height: 1.6,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Row(
                children: [
                  if (t != null && (q.hasVerses || favorite))
                    IconButton(
                      tooltip: favorite ? 'Remove from favorites' : 'Favorite',
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: favorite ? Colors.red : muted,
                      ),
                      onPressed: () {
                        if (favorite) {
                          store.removeFavorite(
                            t.bookCode,
                            t.chapter,
                            t.verse!,
                            t.endVerse,
                          );
                        } else if (q.hasVerses) {
                          store.addFavorite(
                            book: t.bookCode,
                            chapter: t.chapter,
                            verse: t.verse!,
                            endVerse: t.endVerse,
                            version: t.version ?? _version,
                            reference: q.reference,
                            text: q.verses
                                .map(
                                  (v) => v.number > 0
                                      ? '${v.number} ${v.text}'
                                      : v.text,
                                )
                                .join('\n'),
                          );
                        }
                      },
                    ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: Icon(Icons.copy, size: 18, color: muted),
                    onPressed: () => copyWithFeedback(
                      context,
                      '"${_plain(q)}"\n\n— ${q.reference}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: Icon(Icons.ios_share, size: 18, color: muted),
                    onPressed: () => canShareNatively
                        ? shareText('"${_plain(q)}"\n\n— ${q.reference}')
                        : copyWithFeedback(
                            context,
                            '"${_plain(q)}"\n\n— ${q.reference}',
                          ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      '— ${q.reference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  if (t != null)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
