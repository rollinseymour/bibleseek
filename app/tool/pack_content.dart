// Packs the bundled Bible JSON into the compact per-chapter files the web app
// fetches: web/content/bible/<folder>/<BOOK>/<chapter>.json.
//
//   dart run tool/pack_content.dart /path/to/bibleseek/lib/assets
//
// Chapter shape: {"v":[{"n":1,"h":"Heading","p":["text",{"t":"text","j":1},{"t":"note","x":1}]}]}
//   j = words of Jesus, x = editorial note (muted, italic), h = section heading.
// The rules mirror BibleStore.loadChapter in the native app.
import 'dart:convert';
import 'dart:io';

const folders = {
  'kjv': 'kjvJSON',
  'asv': 'asvJSON',
  'asv-rl': 'asvJSONredLetter',
  'bsb': 'bsbJSON',
  'web': 'webJSON',
};

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'usage: dart run tool/pack_content.dart <bibleseek/lib/assets>',
    );
    exit(64);
  }
  final bible = '${args[0]}/Bible';
  final out = Directory('web/content/bible');
  if (out.existsSync()) out.deleteSync(recursive: true);

  final books =
      (jsonDecode(File('$bible/asvJSON/books.json').readAsStringSync())['books']
              as List)
          .cast<Map<String, dynamic>>()
        ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  _write('${out.path}/books.json', [
    for (final b in books)
      {
        'id': b['id'],
        'name': b['name'],
        'commonName': b['commonName'],
        'chapters': b['numberOfChapters'],
      },
  ]);

  var files = 0;
  for (final b in books) {
    final code = b['id'] as String;
    for (var ch = 1; ch <= (b['numberOfChapters'] as int); ch++) {
      final headings = _headings(_read('$bible/bsbJSON/$code/$ch.json'));
      final kjv = _read('$bible/kjvJSON/$code/$ch.json');
      final kjvText = {
        for (final item in _verseItems(kjv))
          item['number'] as int: _plain(_parts(item['content'])),
      };
      for (final entry in folders.entries) {
        final raw = _read('$bible/${entry.value}/$code/$ch.json');
        if (raw == null) {
          stderr.writeln('missing ${entry.value}/$code/$ch.json');
          continue;
        }
        final verses = _pack(
          raw,
          isAsv: entry.key.startsWith('asv'),
          kjvText: kjvText,
        );
        _applyHeadings(verses, headings);
        _write('${out.path}/${entry.key}/$code/$ch.json', {'v': verses});
        files++;
      }
    }
  }
  stdout.writeln('packed $files chapters from ${books.length} books');

  // Study data, copied as-is but minified.
  final data = Directory('web/content/data');
  if (data.existsSync()) data.deleteSync(recursive: true);
  for (final name in dataFiles) {
    _write(
      '${data.path}/$name',
      jsonDecode(File('${args[0]}/$name').readAsStringSync()) as Object,
    );
  }
  stdout.writeln('copied ${dataFiles.length} data files');

  // Folders of per-chapter or per-shard JSON, same layout, minified.
  for (final entry in dataFolders.entries) {
    final dest = Directory('web/content/${entry.value}');
    if (dest.existsSync()) dest.deleteSync(recursive: true);
    var n = 0;
    final src = Directory('${args[0]}/${entry.key}');
    for (final f in src.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final rel = f.path.substring(src.path.length + 1);
      _write('${dest.path}/$rel', jsonDecode(f.readAsStringSync()) as Object);
      n++;
    }
    stdout.writeln('copied $n files from ${entry.key}');
  }
}

const dataFiles = [
  'topics_enriched.json',
  'cross_refs.json',
  'strongs_seed.json',
  'bible_names.json',
  'hitchcock_names.json',
  'videos.json',
  'channels.json',
];

/// Source folder → published folder.
const dataFolders = {
  'Lexicon': 'lexicon',
  'Interlinear': 'interlinear',
  'Reverse': 'reverse',
};

Map<String, dynamic>? _read(String path) {
  final f = File(path);
  return f.existsSync()
      ? jsonDecode(f.readAsStringSync()) as Map<String, dynamic>
      : null;
}

void _write(String path, Object json) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(json));
}

Iterable<Map<String, dynamic>> _verseItems(Map<String, dynamic>? file) =>
    ((file?['chapter']?['content'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .where((i) => i['type'] == 'verse');

/// String runs stay strings; words of Jesus become {"t","j":1}. Note refs and
/// line breaks carry no text of their own and drop out.
List<Object> _parts(Object? raw) {
  final out = <Object>[];
  for (final p in (raw as List?) ?? const []) {
    if (p is String) {
      out.add(p);
    } else if (p is Map && p['text'] is String) {
      out.add(
        p['wordsOfJesus'] == true
            ? {'t': p['text'], 'j': 1}
            : p['text'] as String,
      );
    }
  }
  return out;
}

String _text(Object part) =>
    part is String ? part : (part as Map)['t'] as String;

bool _hasText(List<Object> parts) =>
    parts.any((p) => _text(p).trim().isNotEmpty);

/// Joins runs with a space where the JSON omits one; pilcrows never belong in plain text.
String _plain(List<Object> parts) {
  var buf = '';
  for (final seg in parts.map(_text).where((s) => s.isNotEmpty)) {
    if (buf.isNotEmpty && !buf.endsWith(' ') && !seg.startsWith(' ')) {
      buf += ' ';
    }
    buf += seg;
  }
  if (buf.contains('¶')) {
    buf = buf
        .replaceAll('¶', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .join(' ');
  }
  return buf;
}

List<Map<String, Object>> _pack(
  Map<String, dynamic> file, {
  required bool isAsv,
  required Map<int, String> kjvText,
}) {
  final notes = {
    for (final n
        in ((file['chapter']['footnotes'] as List?) ?? const []).cast<Map>())
      n['noteId'] as int: n['text'] as String,
  };
  final verses = <Map<String, Object>>[];
  for (final item in _verseItems(file)) {
    final n = (item['number'] as int?) ?? 0;
    var parts = _parts(item['content']);
    if (!_hasText(parts)) {
      final kjv = kjvText[n]?.trim() ?? '';
      if (isAsv && kjv.isNotEmpty) {
        parts = [
          kjv,
          {'t': ' (KJV — this verse is omitted in the ASV)', 'x': 1},
        ];
      } else {
        final id = ((item['content'] as List?) ?? const [])
            .whereType<Map>()
            .map((p) => p['noteId'])
            .whereType<int>()
            .firstOrNull;
        final note = id == null ? null : notes[id]?.trim();
        if (note != null && note.isNotEmpty) {
          parts = [
            {'t': note, 'x': 1},
          ];
        }
      }
    }
    verses.add({'n': n, 'p': parts});
  }
  return verses;
}

/// BSB section headings keyed by the verse each precedes; consecutive ones join.
Map<int, String> _headings(Map<String, dynamic>? bsb) {
  final map = <int, String>{};
  final pending = <String>[];
  for (final item
      in ((bsb?['chapter']?['content'] as List?) ?? const []).cast<Map>()) {
    if (item['type'] == 'heading') {
      final text = _parts(item['content']).map(_text).join(' ').trim();
      if (text.isNotEmpty) pending.add(text);
    } else if (item['type'] == 'verse' &&
        item['number'] is int &&
        pending.isNotEmpty) {
      map[item['number'] as int] = pending.join('\n');
      pending.clear();
    }
  }
  return map;
}

/// Exact verse, else the next one, else the last, so a heading is never dropped
/// when a translation's versification lacks the BSB's verse number.
void _applyHeadings(
  List<Map<String, Object>> verses,
  Map<int, String> headings,
) {
  if (verses.isEmpty) return;
  for (final n in headings.keys.toList()..sort()) {
    var i = verses.indexWhere((v) => v['n'] == n);
    if (i < 0) i = verses.indexWhere((v) => (v['n'] as int) > n);
    if (i < 0) i = verses.length - 1;
    final existing = verses[i]['h'] as String?;
    verses[i]['h'] = existing == null
        ? headings[n]!
        : '$existing\n${headings[n]}';
  }
}
