import 'dart:convert';

import 'package:http/http.dart' as http;

import '../web/browser.dart';
import 'models.dart';

/// Fetches packed chapter JSON (see tool/pack_content.dart) and keeps each
/// chapter in memory once loaded.
class BibleStore {
  /// Translations in display order; every picker and cycle derives from this.
  static const versions = ['KJV', 'ASV', 'BSB', 'WEB'];

  static String versionName(String v) => switch (v.toUpperCase()) {
    'ASV' => 'American Standard Version',
    'BSB' => 'Berean Standard Bible',
    'WEB' => 'World English Bible',
    _ => 'King James Version',
  };

  static String nextVersion(String v) {
    final i = versions.indexOf(v.toUpperCase());
    return versions[(i + 1) % versions.length];
  }

  /// Only the ASV has a separate red-letter edition; the others mark words of
  /// Jesus in one file.
  static String folder(String version, {required bool redLetter}) {
    final v = version.toUpperCase();
    if (v == 'ASV') return redLetter ? 'asv-rl' : 'asv';
    return v.toLowerCase();
  }

  final _chapters = <String, Future<List<Verse>>>{};

  Future<List<Verse>> chapter(
    String version,
    String book,
    int chapter, {
    required bool redLetter,
  }) {
    final path =
        'content/bible/${folder(version, redLetter: redLetter)}/$book/$chapter.json';
    return _chapters.putIfAbsent(path, () async {
      try {
        final json = await getJson(path) as Map<String, Object?>;
        return [
          for (final v in json['v'] as List<Object?>)
            Verse.fromJson(v as Map<String, Object?>),
        ];
      } catch (_) {
        _chapters.remove(path);
        rethrow;
      }
    });
  }

  /// One verse's plain text, for journal snippets and comparisons.
  Future<String> verseText(
    String version,
    String book,
    int chapter,
    int verse,
  ) async {
    final verses = await this.chapter(version, book, chapter, redLetter: false);
    for (final v in verses) {
      if (v.number == verse) return v.plainText;
    }
    return '';
  }

  static Future<Object?> getJson(String path) async {
    final res = await http.get(contentUri(path));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', res.request?.url);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
