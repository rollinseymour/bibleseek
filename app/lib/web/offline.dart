import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import 'browser.dart';

/// Saves whole translations into the cache web/sw.js reads from when the
/// network fails, so a saved Bible opens with no connection at all.
class OfflineBibles extends ChangeNotifier {
  OfflineBibles(this.library) {
    if (supported) refresh();
  }

  /// web/sw.js's CACHE.
  static const cacheName = 'bibleseek';

  /// Topics, cross-references, names and the rest, saved with any Bible.
  static const _shared = [
    'content/bible/books.json',
    'content/data/bible_names.json',
    'content/data/channels.json',
    'content/data/cross_refs.json',
    'content/data/hitchcock_names.json',
    'content/data/strongs_seed.json',
    'content/data/topics_enriched.json',
    'content/data/videos.json',
  ];

  /// Rough download sizes, for the Save button.
  static const _megabytes = {'KJV': 11, 'ASV': 18, 'BSB': 11, 'WEB': 11};

  final BibleLibrary library;

  static bool get supported =>
      (web.window as JSObject).has('caches') &&
      (web.window.navigator as JSObject).has('serviceWorker');

  Map<String, int> _present = const {};
  int? usageBytes;

  /// The translation being saved, and how far along it is.
  String? saving;
  int done = 0;
  int total = 0;
  bool _stop = false;

  /// Why the last save stopped short, keyed by translation.
  final errors = <String, String>{};

  int megabytes(String version) => _megabytes[version] ?? 11;

  bool isSaved(String version) =>
      (_present[version] ?? 0) >= _paths(version).length;

  /// Every chapter of [version] (both ASV editions, so red letter can switch
  /// offline) and its search index.
  List<String> _paths(String version) {
    final v = version.toUpperCase();
    final folders = v == 'ASV' ? ['asv', 'asv-rl'] : [v.toLowerCase()];
    return [
      for (final f in folders)
        for (final b in library.books)
          for (var c = 1; c <= b.chapters; c++)
            'content/bible/$f/${b.id}/$c.json',
      'content/search/${v.toLowerCase()}.json',
    ];
  }

  static String _url(String path) => contentUri(path).toString();

  static Future<web.Cache> _open() => web.window.caches.open(cacheName).toDart;

  static Future<Set<String>> _cached(web.Cache cache) async => {
    for (final r in (await cache.keys().toDart).toDart) r.url,
  };

  Future<void> refresh() async {
    try {
      final have = await _cached(await _open());
      _present = {
        for (final v in BibleStore.versions)
          v: _paths(v).where((p) => have.contains(_url(p))).length,
      };
      final estimate = await web.window.navigator.storage.estimate().toDart;
      usageBytes = estimate.usage;
    } catch (_) {
      // Storage blocked (a private window): leave the counts as they were.
    }
    notifyListeners();
  }

  Future<void> save(String version) async {
    if (saving != null) return;
    saving = version;
    errors.remove(version);
    _stop = false;
    done = 0;
    total = 0;
    notifyListeners();
    try {
      // Asks the browser not to clear this site's storage under pressure.
      await web.window.navigator.storage.persist().toDart;
    } catch (_) {}
    var failed = false;
    try {
      final cache = await _open();
      final have = await _cached(cache);
      final todo = [
        for (final p in [..._shared, ..._paths(version)])
          if (!have.contains(_url(p))) _url(p),
      ];
      total = todo.length;
      notifyListeners();
      var next = 0;
      Future<void> worker() async {
        while (!_stop && !failed && next < todo.length) {
          final url = todo[next++];
          try {
            await cache.add(url.toJS).toDart;
          } catch (_) {
            failed = true;
          }
          done++;
          if (done % 20 == 0 || done == total) notifyListeners();
        }
      }

      await Future.wait([for (var i = 0; i < 6; i++) worker()]);
    } catch (_) {
      failed = true;
    }
    if (failed) {
      errors[version] =
          'Couldn’t finish saving. Check your connection and the space on this device, then try again.';
    }
    saving = null;
    await refresh();
  }

  void stop() => _stop = true;

  Future<void> remove(String version) async {
    try {
      final cache = await _open();
      final urls = _paths(version).map(_url).toList();
      for (var i = 0; i < urls.length; i += 100) {
        await Future.wait([
          for (final u in urls.skip(i).take(100)) cache.delete(u.toJS).toDart,
        ]);
      }
    } catch (_) {}
    errors.remove(version);
    await refresh();
  }
}
