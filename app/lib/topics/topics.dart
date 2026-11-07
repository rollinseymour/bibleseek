import 'package:flutter/material.dart';

import '../bible/bible_store.dart';

/// A topical study from `topics_enriched.json`: title, category, summary and
/// curated scripture references (verse text loads on demand).
class Topic {
  const Topic({
    required this.title,
    required this.category,
    required this.summary,
    required this.quotes,
  });

  factory Topic.fromJson(Map<String, Object?> j) => Topic(
    title: j['title'] as String? ?? '',
    category: j['category'] as String? ?? '',
    summary: j['summary'] as String? ?? '',
    quotes: [
      for (final q in (j['quotes'] as List? ?? const []).whereType<Map>())
        if (q['reference'] is String) q['reference'] as String,
    ],
  );

  final String title;
  final String category;
  final String summary;
  final List<String> quotes;

  String get verseCountLabel =>
      quotes.length == 1 ? '1 verse' : '${quotes.length} verses';
  String get cleanTitle => title.replaceAll('\n', ' ').replaceAll('\r', ' ');
}

class TopicsCatalog {
  static Future<List<Topic>>? _loaded;

  static Future<List<Topic>> load(BibleStore store) => _loaded ??= () async {
    try {
      final raw =
          await store.data('topics_enriched.json') as Map<String, Object?>;
      return [
        for (final t
            in (raw['topics'] as List).whereType<Map<String, Object?>>())
          if (Topic.fromJson(t) case final topic when topic.title.isNotEmpty)
            topic,
      ];
    } catch (_) {
      _loaded = null;
      rethrow;
    }
  }();

  /// Display order for categories; unknown ones sort to the end.
  static const categoryOrder = [
    'Closeness with God',
    'Christ & the Spirit',
    'Character of a Believer',
    'Sin & Temptation',
    'Suffering & Help',
    'Home & Stewardship',
    'Calling & Service',
    "God's Power & End Times",
    'Wisdom & Discernment',
    'Worship & Praise',
    'Prayer & Communion',
    'Hope & Encouragement',
    'Mission & Witness',
    'People of the Bible',
    'Parables & Miracles',
    'Emotions & the Heart',
    'Relationships & Community',
    'Everyday Life',
    "God's Names & Attributes",
    'The Church',
  ];

  /// Every whitespace-separated term must appear in the title, category or
  /// summary. Title matches rank first, then title+category, then summary.
  static List<Topic> search(List<Topic> topics, String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return topics;
    final ranked = <({int rank, int index, Topic topic})>[];
    for (final (i, t) in topics.indexed) {
      final title = t.title.toLowerCase();
      final titleCat = '$title ${t.category.toLowerCase()}';
      final haystack = '$titleCat ${t.summary.toLowerCase()}';
      if (!terms.every(haystack.contains)) continue;
      final rank = terms.every(title.contains)
          ? 0
          : (terms.every(titleCat.contains) ? 1 : 2);
      ranked.add((rank: rank, index: i, topic: t));
    }
    ranked.sort(
      (a, b) => a.rank != b.rank
          ? a.rank.compareTo(b.rank)
          : a.index.compareTo(b.index),
    );
    return [for (final r in ranked) r.topic];
  }

  static List<({String category, List<Topic> topics})> grouped(
    List<Topic> topics,
  ) {
    final buckets = <String, List<Topic>>{};
    for (final t in topics) {
      buckets
          .putIfAbsent(t.category.isEmpty ? 'Other' : t.category, () => [])
          .add(t);
    }
    return [
      for (final c in categoryOrder)
        if (buckets.remove(c) case final list?) (category: c, topics: list),
      for (final c in buckets.keys.toList()..sort())
        (category: c, topics: buckets[c]!),
    ];
  }

  /// Walks every topic once per cycle, a different category day to day, by
  /// striding a per-day counter with a step coprime to the topic count.
  static Topic? topicOfDay(List<Topic> topics, [DateTime? date]) {
    if (topics.isEmpty) return null;
    final d = date ?? DateTime.now();
    final doy = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(d.year)).inDays;
    final dayNumber = d.year * 366 + doy;
    final count = topics.length;
    return topics[((dayNumber * _stride(count)) % count + count) % count];
  }

  static int _stride(int count) {
    if (count <= 2) return 1;
    int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
    var s = (count * 0.61803398875).floor().clamp(1, count);
    while (gcd(s, count) != 1) {
      s++;
    }
    return s;
  }

  static const _stopWords = {
    'the',
    'a',
    'an',
    'is',
    'are',
    'be',
    'been',
    'being',
    'was',
    'were',
    'and',
    'or',
    'but',
    'if',
    'as',
    'of',
    'in',
    'on',
    'at',
    'to',
    'for',
    'with',
    'from',
    'by',
    'into',
    'onto',
    'about',
    'over',
    'under',
    'this',
    'that',
    'these',
    'those',
    'his',
    'her',
    'their',
    'our',
    'your',
    'they',
    'them',
    'we',
    'us',
    'you',
    'he',
    'she',
    'it',
    'who',
    'whom',
    'which',
    'what',
    'when',
    'where',
    'why',
    'how',
    'all',
    'any',
    'each',
    'every',
    'no',
    'not',
    'so',
    'than',
    'too',
    'very',
    'just',
    'only',
    'also',
    'such',
    'some',
    'most',
    'more',
    'less',
    'one',
    'two',
    'three',
    'do',
    'does',
    'did',
    'have',
    'has',
    'had',
    'will',
    'shall',
    'should',
    'would',
    'could',
    'may',
    'might',
    'must',
    'can',
    'cant',
    'cannot',
    'use',
    'using',
    'used',
    'through',
    'across',
    'between',
    'because',
    'while',
  };

  static Set<String> _tokens(String text) => {
    for (final w in text.toLowerCase().split(
      RegExp(r'[^\p{L}]+', unicode: true),
    ))
      if (w.length >= 4 && !_stopWords.contains(w)) w,
  };

  /// Topics whose summaries share the most words with [topic]'s.
  static List<Topic> related(Topic topic, List<Topic> all, {int limit = 4}) {
    final mine = _tokens(topic.summary);
    if (mine.isEmpty) return const [];
    final scored =
        [
          for (final t in all)
            if (t.title != topic.title)
              if (mine.intersection(_tokens(t.summary)).length case final n
                  when n > 0)
                (topic: t, score: n),
        ]..sort(
          (a, b) => a.score != b.score
              ? b.score.compareTo(a.score)
              : a.topic.title.compareTo(b.topic.title),
        );
    return [for (final s in scored.take(limit)) s.topic];
  }

  /// A soft tint per category, cycled in display order.
  static Color tint(String category) {
    const palette = [
      Color(0xFFA78BFA),
      Color(0xFFD4AF37),
      Color(0xFF5EEAD4),
      Color(0xFFF0997B),
      Color(0xFF85B7EB),
      Color(0xFFED93B1),
    ];
    final i = categoryOrder.indexOf(category);
    return palette[(i < 0 ? 0 : i) % palette.length];
  }
}
