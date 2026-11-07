class BibleBook {
  const BibleBook({
    required this.id,
    required this.name,
    required this.commonName,
    required this.order,
    required this.chapters,
  });

  /// USFM code, e.g. "GEN".
  final String id;
  final String name;
  final String commonName;

  /// 1...66.
  final int order;
  final int chapters;
}

/// One renderable run of verse text.
class VersePart {
  const VersePart(this.text, {this.wordsOfJesus = false, this.isNote = false});

  factory VersePart.fromJson(Object json) => switch (json) {
    final String s => VersePart(s),
    final Map<String, Object?> m => VersePart(
      m['t'] as String? ?? '',
      wordsOfJesus: m['j'] == 1,
      isNote: m['x'] == 1,
    ),
    _ => const VersePart(''),
  };

  final String text;
  final bool wordsOfJesus;

  /// Editorial text shown in place of an omitted verse; rendered muted and italic.
  final bool isNote;
}

class Verse {
  const Verse({required this.number, required this.parts, this.heading});

  factory Verse.fromJson(Map<String, Object?> json) => Verse(
    number: json['n'] as int,
    parts: [
      for (final p in (json['p'] as List<Object?>)) VersePart.fromJson(p!),
    ],
    heading: json['h'] as String?,
  );

  final int number;
  final List<VersePart> parts;

  /// Section heading shown above this verse (BSB-sourced, shared across versions).
  final String? heading;

  /// The parts joined the way the reader displays them: a space is inserted
  /// between adjacent runs when the data omits one. Offsets into this string
  /// are what phrase highlights and notes index (UTF-16).
  String get renderedBody {
    final buf = StringBuffer();
    var last = '';
    for (final part in parts) {
      final seg = part.text;
      if (seg.isEmpty) continue;
      if (last.isNotEmpty && !last.endsWith(' ') && !seg.startsWith(' ')) {
        buf.write(' ');
      }
      buf.write(seg);
      last = seg;
    }
    return buf.toString();
  }

  /// Text for copy, share, bookmarks and search: pilcrow marks never belong here.
  String get plainText {
    final body = renderedBody;
    if (!body.contains('¶')) return body;
    return body
        .replaceAll('¶', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .join(' ');
  }
}
