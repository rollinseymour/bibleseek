import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../design/reader_fonts.dart';
import '../memory/memory_screen.dart';
import '../more/settings_screen.dart';
import '../plans/plans.dart';
import '../plans/plans_screen.dart';
import '../reader/reader_model.dart';
import '../settings/settings_model.dart';
import '../share/share_card.dart';
import '../study/compare_screen.dart';
import '../study/cross_references.dart';
import '../topics/topics.dart';
import '../topics/topics_screen.dart';
import '../videos/videos.dart';
import '../web/browser.dart';
import '../widgets/copy.dart';
import '../widgets/mouse_drag_scroll.dart';
import '../wordstudy/lexicon.dart';
import '../wordstudy/strongs_card.dart';
import '../wordstudy/word_study_screen.dart';
import 'search_results_screen.dart';
import 'verse_of_the_day.dart';
import 'verse_search.dart';

const _gold = Color(0xFFC9A227);

/// A Word Study pick for Home: a Strong's word with example verses, or a name.
typedef WordPick = ({
  String id,
  String word,
  StrongsEntry? entry,
  List<WordExample> examples,
  NameStudy? name,
});

/// Greeting, search (verses, topics, word study, videos), the active plan,
/// a note from a year ago, the Verse of the Day, Explore, Continue reading,
/// today's topic and a word to study.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _wordIdKey = 'home_word_study_word';
  static const _wordRolledKey = 'home_word_study_rolled_at';

  late final AppModel app;
  final _query = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _token = 0;
  int _homeReset = 0;

  late String _version;
  String _testament = 'all';
  bool _exact = true;
  List<VerseHit> _verseHits = const [];
  List<Topic> _topicHits = const [];
  StrongsEntry? _wordHit;
  List<Video> _videoHits = const [];
  bool _indexing = false;
  final _dismissed = <String>{};

  List<Topic> _topics = const [];
  WordPick? _wordStudy;

  bool get _searching => _query.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    app = context.read<AppModel>()..addListener(_onApp);
    _homeReset = app.homeReset;
    _version = ReadingPosition.load(context.read())?.version ?? 'All';
    TopicsCatalog.load(context.read<BibleStore>()).then((t) {
      if (mounted) setState(() => _topics = t);
    }, onError: (_) {});
    _loadWordStudy();
  }

  @override
  void dispose() {
    app.removeListener(_onApp);
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onApp() {
    if (app.homeReset != _homeReset) {
      _homeReset = app.homeReset;
      _clearSearch();
    }
  }

  void _clearSearch() {
    _query.clear();
    _focus.unfocus();
    setState(() {
      _verseHits = const [];
      _topicHits = const [];
      _videoHits = const [];
      _wordHit = null;
    });
  }

  void _open(ReaderTarget t) {
    _clearSearch();
    app.open(t);
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  String get _greeting => switch (DateTime.now().hour) {
    >= 6 && < 12 => 'Mark 3:1-7',
    >= 12 && < 18 => 'I pray daily.',
    >= 18 && < 20 => 'I act in obedience.',
    _ => 'I love the Lord.',
  };

  // MARK: search

  void _changed(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final token = ++_token;
    final q = _query.text.trim();
    if (q.isEmpty) return _clearSearch();
    final lq = q.toLowerCase();
    final store = context.read<BibleStore>();
    final data = context.read<WordStudyData>();
    final search = context.read<VerseSearch>();

    final topicHits = q.length >= 2
        ? TopicsCatalog.search(_topics, q).take(5).toList()
        : <Topic>[];
    final terms = lq.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    var videoHits = <Video>[];
    try {
      final cat = await VideosCatalog.videos(store);
      videoHits = terms.isEmpty
          ? []
          : [
              ...cat.sermons,
              ...cat.podcasts,
            ].where((v) => terms.every(v.haystack.contains)).take(3).toList();
    } catch (_) {}
    StrongsEntry? wordHit;
    if (!q.contains(' ') && q.length >= 2) {
      try {
        await data.ready();
        wordHit = data.lookup(q).firstOrNull;
      } catch (_) {}
    }
    if (!mounted || token != _token) return;
    setState(() {
      _topicHits = topicHits;
      _videoHits = videoHits;
      _wordHit = wordHit;
    });

    if (q.length < 3) {
      setState(() => _verseHits = const []);
      return;
    }
    final versions = _version == 'All' ? <String>{} : {_version};
    setState(
      () => _indexing = !(versions.isEmpty
          ? BibleStore.versions.every(search.isLoaded)
          : search.isLoaded(_version)),
    );
    List<VerseHit> hits;
    try {
      hits = await search.search(
        q,
        versions: versions,
        testament: _testament,
        exact: _exact,
        limit: 9,
      );
    } catch (_) {
      hits = const [];
    }
    if (!mounted || token != _token) return;
    setState(() {
      _verseHits = hits;
      _indexing = false;
    });
  }

  ReaderTarget? get _searchTarget {
    final q = _query.text.trim();
    return q.length >= 2
        ? context.read<BibleLibrary>().parseReference(q)
        : null;
  }

  // MARK: word study pick

  Future<WordPick?> _resolve(String id) async {
    final data = context.read<WordStudyData>();
    Future<WordPick?> word(String w) async {
      final e = data.lookup(w).firstOrNull;
      if (e == null) return null;
      final ex = await data.examples(e.number);
      return ex.isEmpty
          ? null
          : (id: 'w:$w', word: w, entry: e, examples: ex, name: null);
    }

    WordPick? name(String key) {
      final study = data.name(key);
      if (study == null) return null;
      final display = study.name.isEmpty ? key : study.name;
      if (display.contains(' ')) return null;
      return (
        id: 'n:$key',
        word: display,
        entry: null,
        examples: const [],
        name: study,
      );
    }

    if (id.startsWith('w:')) return word(id.substring(2));
    if (id.startsWith('n:')) return name(id.substring(2));
    return await word(id) ?? name(id);
  }

  /// Coin-flips between Strong's words and names so both stay in rotation.
  Future<WordPick?> _random({String? excluding}) async {
    final data = context.read<WordStudyData>();
    final words = data.words(), names = data.nameKeys();
    if (words.isEmpty && names.isEmpty) return null;
    final rng = Random();
    for (var i = 0; i < 40; i++) {
      final useName = names.isNotEmpty && (words.isEmpty || rng.nextBool());
      final id = useName
          ? 'n:${names[rng.nextInt(names.length)]}'
          : 'w:${words[rng.nextInt(words.length)]}';
      if (id == excluding) continue;
      final pick = await _resolve(id);
      if (pick != null) return pick;
    }
    return null;
  }

  /// Keeps the same word for 24 hours, then rolls a new one.
  Future<void> _loadWordStudy({bool shuffle = false}) async {
    final prefs = context.read<Prefs>();
    try {
      await context.read<WordStudyData>().ready();
    } catch (_) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final stored = prefs.getString(_wordIdKey);
    WordPick? pick;
    if (!shuffle &&
        stored != null &&
        now - prefs.getDouble(_wordRolledKey, 0) < 24 * 60 * 60 * 1000) {
      pick = await _resolve(stored);
    }
    final rolled = pick == null;
    pick ??=
        await _random(excluding: shuffle ? _wordStudy?.id ?? stored : stored) ??
        await _random();
    if (pick == null || !mounted) return;
    if (rolled) {
      prefs.setString(_wordIdKey, pick.id);
      prefs.setDouble(_wordRolledKey, now.toDouble());
    }
    setState(() => _wordStudy = pick);
  }

  // MARK: build

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.read<BibleLibrary>();
    final greetingTarget = library.parseReference(_greeting);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _focus.unfocus,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bible Seek',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Settings',
                        onPressed: () => _push(const SettingsScreen()),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (greetingTarget != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => _open(greetingTarget),
                        child: Text(
                          _greeting,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      _greeting,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _query,
                    focusNode: _focus,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    onChanged: _changed,
                    onSubmitted: (_) {
                      if (_searchTarget case final t?) _open(t);
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search a word or go to a verse',
                      filled: true,
                      fillColor: scheme.onSurface.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.cancel),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_searching) ..._searchPanel() else ..._cards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: search panel

  List<Widget> _searchPanel() {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.text.trim();
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        s,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
    Widget card({required Widget child, required VoidCallback onTap}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(10), child: child),
            ),
          ),
        );
    final noMatches =
        !_indexing &&
        q.length >= 2 &&
        _verseHits.isEmpty &&
        _topicHits.isEmpty &&
        _wordHit == null &&
        _videoHits.isEmpty &&
        _searchTarget == null;
    return [
      if (_searchTarget case final t?)
        card(
          onTap: () => _open(t),
          child: Row(
            children: [
              Icon(Icons.arrow_circle_right, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Go to ${context.read<BibleLibrary>().name(t.bookCode)} ${t.chapter}${t.verse == null ? '' : ':${t.verse}'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      SearchFilters(
        version: _version,
        testament: _testament,
        exact: _exact,
        onChanged: (v, t, e) {
          setState(() {
            _version = v;
            _testament = t;
            _exact = e;
          });
          _runSearch();
        },
      ),
      if (_indexing)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Searching…',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      if (_verseHits.isNotEmpty) ...[
        label('Verses'),
        for (final h in _verseHits)
          VerseHitCard(
            hit: h,
            onTap: () => _open(
              ReaderTarget(
                bookCode: h.bookCode,
                chapter: h.chapter,
                verse: h.verse,
                version: h.version,
              ),
            ),
          ),
        Center(
          child: TextButton(
            onPressed: () => _push(
              SearchResultsScreen(
                query: q,
                version: _version,
                testament: _testament,
                exact: _exact,
              ),
            ),
            child: const Text(
              'See all results',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      if (_topicHits.isNotEmpty) ...[
        label('Topics'),
        for (final t in _topicHits)
          card(
            onTap: () => _push(TopicDetailScreen(topic: t, allTopics: _topics)),
            child: Row(
              children: [
                Icon(Icons.layers_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.cleanTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        t.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      if (_wordHit case final e?) ...[
        label('Word study'),
        card(
          onTap: () => _push(WordStudyScreen(initialQuery: q)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    e.lemma,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (e.translit.isNotEmpty)
                    Text(
                      e.translit,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: scheme.primary,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    e.number,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                e.gloss,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
      if (_videoHits.isNotEmpty) ...[
        label('Videos & podcasts'),
        for (final v in _videoHits)
          card(
            onTap: () => openExternal(v.youtubeUrl),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: v.thumbnailUrl == null
                      ? const SizedBox(width: 64, height: 36)
                      : youtubeImage(
                          v.thumbnailUrl!,
                          width: 64,
                          height: 36,
                          placeholder: Container(
                            width: 64,
                            height: 36,
                            color: scheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (v.speakers.isNotEmpty)
                        Text(
                          v.speakers,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      if (noMatches)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'No matches for “$q”.',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
    ];
  }

  // MARK: cards

  Widget _dismiss(String key) => IconButton(
    tooltip: 'Hide for now',
    visualDensity: VisualDensity.compact,
    iconSize: 14,
    onPressed: () => setState(() => _dismissed.add(key)),
    icon: const Icon(Icons.close),
  );

  List<Widget> _cards() {
    final position = ReadingPosition.load(context.read<Prefs>());
    final today = TopicsCatalog.topicOfDay(_topics);
    return [
      if (!_dismissed.contains('plan')) ?_planCard(),
      if (!_dismissed.contains('yearago')) ?_yearAgoCard(),
      if (!_dismissed.contains('votd')) _votdCard(),
      _explore(),
      if (position != null && !_dismissed.contains('continue'))
        _continueCard(position),
      if (today != null && !_dismissed.contains('topic')) ...[
        _sectionTitle('Today’s Topic'),
        _topicCard(today),
        const SizedBox(height: 18),
      ],
      if (_wordStudy case final ws?) ..._wordStudySection(ws),
    ];
  }

  Widget _sectionTitle(String s, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            s,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget? _planCard() {
    final store = context.watch<PlanStore>();
    final ids = store.activeIds.toList()..sort();
    if (ids.isEmpty) return null;
    final plan = store
        .allPlans(context.read<BibleLibrary>())
        .where((p) => p.id == ids.first)
        .firstOrNull;
    if (plan == null) return null;
    final scheme = Theme.of(context).colorScheme;
    final day = store.nextDay(plan) ?? plan.totalDays;
    final readings = plan.readingsFor(day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 14),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CONTINUE YOUR PLAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: scheme.primary,
                    ),
                  ),
                ),
                _dismiss('plan'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (day >= plan.totalDays)
                    Text(
                      'Plan complete — well done!',
                      style: TextStyle(color: scheme.primary),
                    )
                  else ...[
                    Text(
                      'Day ${day + 1} of ${plan.totalDays}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: day / (plan.totalDays < 1 ? 1 : plan.totalDays),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Today: ${readings.map((r) => r.label).join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (readings.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () => _open(
                              ReaderTarget(
                                bookCode: readings.first.bookCode,
                                chapter: readings.first.startChapter,
                              ),
                            ),
                            icon: const Icon(Icons.menu_book, size: 18),
                            label: const Text('Read today'),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              _push(PlanDetailScreen(planId: plan.id)),
                          child: const Text('View plan'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _yearAgoCard() {
    final store = context.watch<AnnotationStore>();
    final now = DateTime.now();
    final target = DateTime(
      now.year - 1,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    const window = 7 * 24 * 60 * 60 * 1000;
    ({
      String version,
      String book,
      int chapter,
      int verse,
      String text,
      int createdAt,
    })?
    best;
    for (final n in store.datedNotes()) {
      final delta = (n.createdAt - target).abs();
      if (delta <= window &&
          (best == null || delta < (best.createdAt - target).abs())) {
        best = n;
      }
    }
    if (best == null) return null;
    final note = best;
    final scheme = Theme.of(context).colorScheme;
    final ref =
        '${context.read<BibleLibrary>().name(note.book)} ${note.chapter}:${note.verse}';
    final snippet = note.text.length > 120
        ? '${note.text.substring(0, 120)}…'
        : note.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(
            ReaderTarget(
              bookCode: note.book,
              chapter: note.chapter,
              verse: note.verse,
              version: note.version,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.history, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'A year ago…',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'You noted $ref',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '“$snippet”',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _dismiss('yearago'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _votdCard() {
    final v = VerseOfTheDay.today;
    final scheme = Theme.of(context).colorScheme;
    final target = context.read<BibleLibrary>().parseReference(v.ref);
    final font = context.watch<SettingsModel>().readerFont;
    final share = '“${v.text}”\n— ${v.ref} (KJV)';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: _gold.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _gold.withValues(alpha: 0.32)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: target == null
              ? null
              : () => _open(
                  ReaderTarget(
                    bookCode: target.bookCode,
                    chapter: target.chapter,
                    verse: target.verse,
                    endVerse: target.endVerse,
                    version: 'KJV',
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'VERSE OF THE DAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: _gold,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _gold,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        final r = context.read<BibleLibrary>().parseRange(
                          v.ref,
                        );
                        if (r == null) {
                          copyWithFeedback(context, share);
                        } else {
                          shareVerses(
                            context,
                            reference: v.ref,
                            version: 'KJV',
                            book: r.book.id,
                            chapter: r.chapter,
                            verses: [for (var n = r.start; n <= r.end; n++) n],
                          );
                        }
                      },
                      child: const Text(
                        'Share',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _dismiss('votd'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.text,
                        style: readerTextStyle(
                          font,
                          fontSize: v.text.length > 264 ? 16 : 20,
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        v.ref,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _explore() {
    final tiles = <(IconData, String, VoidCallback)>[
      (Icons.menu_book_outlined, 'Bible', () => app.selectTab(AppTab.bible)),
      (Icons.layers_outlined, 'Topics', () => _push(const TopicsScreen())),
      (
        Icons.calendar_month_outlined,
        'Reading Plans',
        () => _push(const ReadingPlansScreen()),
      ),
      (Icons.translate, 'Word Study', () => _push(const WordStudyScreen())),
      (
        Icons.psychology_outlined,
        'Memory Verses',
        () => _push(const MemoryVersesScreen()),
      ),
      (
        Icons.smart_display_outlined,
        'Channels',
        () => _push(const ChannelsScreen()),
      ),
      (Icons.compare_arrows, 'Compare', () => _push(const CompareScreen())),
      (Icons.bookmark_border, 'Journal', () => app.selectTab(AppTab.journal)),
      (
        Icons.link,
        'Cross-References',
        () => _push(const CrossReferencesScreen()),
      ),
      (Icons.favorite_border, 'Favorites', () => app.openJournal('Favorites')),
    ];
    final scheme = Theme.of(context).colorScheme;
    Widget tile((IconData, String, VoidCallback) t) => Material(
      color: scheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: t.$3,
        child: SizedBox(
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(t.$1, color: scheme.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                t.$2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            'Explore',
            trailing: _dismissed.contains('votd')
                ? ActionChip(
                    avatar: const Icon(Icons.wb_sunny, size: 16, color: _gold),
                    label: const Text(
                      'Verse of the Day',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _gold.withValues(alpha: 0.15),
                    side: BorderSide(color: _gold.withValues(alpha: 0.32)),
                    shape: const StadiumBorder(),
                    onPressed: () => setState(() => _dismissed.remove('votd')),
                  )
                : null,
          ),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 560) {
                final cols = c.maxWidth >= 700 ? 5 : 4;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: (c.maxWidth - 12 * (cols - 1)) / cols / 90,
                  children: [for (final t in tiles) tile(t)],
                );
              }
              return _ExplorePager(
                tileAspect: (c.maxWidth - 12) / 2 / 90,
                pages: [
                  for (var i = 0; i < tiles.length; i += 4)
                    [for (final t in tiles.skip(i).take(4)) tile(t)],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _continueCard(ReadingPosition p) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: scheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(
            ReaderTarget(
              bookCode: p.bookCode,
              chapter: p.chapter,
              version: p.version,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Continue',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${context.read<BibleLibrary>().name(p.bookCode)} ${p.chapter} · ${p.version}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicCard(Topic t) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _push(TopicDetailScreen(topic: t, allTopics: _topics)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_stories_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.cleanTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (t.summary.isNotEmpty)
                      Text(
                        t.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      t.verseCountLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _wordStudySection(WordPick ws) {
    final scheme = Theme.of(context).colorScheme;
    return [
      _sectionTitle('Word Study'),
      Row(
        children: [
          Text(
            ws.word.isEmpty
                ? ''
                : ws.word[0].toUpperCase() + ws.word.substring(1),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Another word',
            onPressed: () => _loadWordStudy(shuffle: true),
            icon: Icon(Icons.shuffle, color: scheme.primary),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (ws.name case final name?)
        NameStudyCard(study: name, showName: false)
      else if (ws.entry case final e?)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    e.lemma,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (e.translit.isNotEmpty)
                    Text(
                      e.translit,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: scheme.primary,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${e.isGreek ? 'Greek' : 'Hebrew'} · ${e.number}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (e.gloss.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  e.gloss,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final ex in ws.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ExampleRow(example: ex),
                ),
            ],
          ),
        ),
    ];
  }
}

/// Explore tiles four to a page on phones, swipeable, with page dots.
class _ExplorePager extends StatefulWidget {
  const _ExplorePager({required this.pages, required this.tileAspect});
  final List<List<Widget>> pages;

  /// Width / height of one tile, so two rows fill the pager exactly.
  final double tileAspect;

  @override
  State<_ExplorePager> createState() => _ExplorePagerState();
}

class _ExplorePagerState extends State<_ExplorePager> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 192,
          child: MouseDragScroll(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final page in widget.pages)
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: widget.tileAspect,
                    children: page,
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.pages.length; i++)
              GestureDetector(
                onTap: () => _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Version / testament / exact-match filters for verse search.
class SearchFilters extends StatelessWidget {
  const SearchFilters({
    super.key,
    required this.version,
    required this.testament,
    required this.exact,
    required this.onChanged,
  });
  final String version;
  final String testament;
  final bool exact;
  final void Function(String version, String testament, bool exact) onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onTap(),
      ),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final v in ['All', ...BibleStore.versions])
          chip(v, version == v, () => onChanged(v, testament, exact)),
        const SizedBox(width: 8),
        for (final (key, label) in const [
          ('all', 'All'),
          ('old', 'OT'),
          ('new', 'NT'),
        ])
          chip(label, testament == key, () => onChanged(version, key, exact)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: exact,
              onChanged: (e) => onChanged(version, testament, e),
            ),
            const Text('Exact', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

/// One search hit: reference, translation badge and the verse.
class VerseHitCard extends StatelessWidget {
  const VerseHitCard({super.key, required this.hit, required this.onTap});
  final VerseHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final font = context.read<SettingsModel>().readerFont;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hit.reference,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        hit.version,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hit.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: readerTextStyle(
                    font,
                    fontSize: 14,
                    color: scheme.onSurface,
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
