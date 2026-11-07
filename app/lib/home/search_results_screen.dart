import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../topics/topics.dart';
import '../topics/topics_screen.dart';
import 'home_screen.dart';
import 'verse_search.dart';

/// Every verse matching a search, grouped by book in canonical order, with
/// topic matches and the version / testament / exact-match filters.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    this.version = 'All',
    this.testament = 'all',
    this.exact = true,
  });
  final String query;
  final String version;
  final String testament;
  final bool exact;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final _query = TextEditingController(text: widget.query);
  late String _version = widget.version;
  late String _testament = widget.testament;
  late bool _exact = widget.exact;
  Timer? _debounce;
  int _token = 0;
  bool _searching = false;
  List<VerseHit> _hits = const [];
  List<Topic> _topics = const [];
  List<Topic> _topicHits = const [];

  @override
  void initState() {
    super.initState();
    TopicsCatalog.load(context.read<BibleStore>()).then((t) {
      _topics = t;
      _search();
    }, onError: (_) => _search());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final token = ++_token;
    final q = _query.text.trim();
    setState(() {
      _topicHits = q.length >= 2 ? TopicsCatalog.search(_topics, q) : const [];
      _searching = q.length >= 3;
      if (q.length < 3) _hits = const [];
    });
    if (q.length < 3) return;
    List<VerseHit> hits;
    try {
      hits = await context.read<VerseSearch>().search(
        q,
        versions: _version == 'All' ? const {} : {_version},
        testament: _testament,
        exact: _exact,
      );
    } catch (_) {
      hits = const [];
    }
    if (!mounted || token != _token) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.read<BibleLibrary>();
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final groups = <String, List<VerseHit>>{};
    for (final h in _hits) {
      groups.putIfAbsent(h.bookCode, () => []).add(h);
    }
    final rows = <Object>[];
    for (final e in groups.entries) {
      rows
        ..add(e.key)
        ..addAll(e.value);
    }
    final q = _query.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList.list(
                  children: [
                    TextField(
                      controller: _query,
                      autocorrect: false,
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 300),
                          _search,
                        );
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search the Bible',
                        filled: true,
                        fillColor: scheme.onSurface.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SearchFilters(
                      version: _version,
                      testament: _testament,
                      exact: _exact,
                      onChanged: (v, t, e) {
                        _version = v;
                        _testament = t;
                        _exact = e;
                        _search();
                      },
                    ),
                    if (_topicHits.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          'Topics',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                      for (final t in _topicHits.take(10))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            t.cleanTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(t.category),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => TopicDetailScreen(
                                topic: t,
                                allTopics: _topics,
                              ),
                            ),
                          ),
                        ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: _searching
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Searching…',
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            )
                          : _hits.isEmpty
                          ? Text(
                              q.length < 3
                                  ? 'Type at least 3 letters to search.'
                                  : 'No verses match “$q”.',
                              style: TextStyle(color: muted),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_hits.length} verse${_hits.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${groups.length} book${groups.length == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    if (r is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                library.name(r),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: muted,
                                ),
                              ),
                            ),
                            Text(
                              '${groups[r]!.length}',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      );
                    }
                    final h = r as VerseHit;
                    return VerseHitCard(
                      hit: h,
                      onTap: () {
                        context.read<AppModel>().open(
                          ReaderTarget(
                            bookCode: h.bookCode,
                            chapter: h.chapter,
                            verse: h.verse,
                            version: h.version,
                          ),
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
