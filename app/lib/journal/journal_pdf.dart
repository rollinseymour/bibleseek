import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../annotations/highlight_palette.dart';

enum PdfKind { highlight, note, bookmark, favorite }

class PdfEntry {
  const PdfEntry({
    required this.kind,
    required this.bookName,
    required this.bookOrder,
    required this.chapter,
    required this.verse,
    required this.reference,
    required this.text,
    this.colorHex,
  });

  final PdfKind kind;
  final String bookName;
  final int bookOrder;
  final int chapter;
  final int verse;
  final String reference;

  /// Verse text for bookmarks and favorites, note text for notes.
  final String text;
  final String? colorHex;
}

/// The journal as a paginated Letter-size PDF, grouped by book in canonical
/// order. Highlights condense to one line per color ("Orange: 2:3, 3:20-22");
/// notes, bookmarks and favorites keep their reference and text.
class JournalPdf {
  static const _accent = PdfColor(0.04, 0.36, 0.27);
  static const _ink = PdfColor(0.1, 0.1, 0.1);
  static const _dim = PdfColor(0.38, 0.38, 0.38);

  static Future<List<int>> generate(
    String title,
    List<PdfEntry> entries,
  ) async {
    Future<pw.Font> font(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));
    final theme = pw.ThemeData.withFont(
      base: await font('Roboto-Regular.ttf'),
      bold: await font('Roboto-Bold.ttf'),
      italic: await font('Roboto-Italic.ttf'),
    );
    int count(PdfKind k) => entries.where((e) => e.kind == k).length;
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final body = <pw.Widget>[
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 26,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        '${months[now.month - 1]} ${now.day}, ${now.year}',
        style: const pw.TextStyle(fontSize: 11, color: _dim),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        '${plural(count(PdfKind.highlight), 'highlight')} · ${plural(count(PdfKind.note), 'note')} · '
        '${plural(count(PdfKind.bookmark), 'bookmark')} · ${plural(count(PdfKind.favorite), 'favorite')}',
        style: const pw.TextStyle(fontSize: 12, color: _accent),
      ),
      pw.SizedBox(height: 18),
      if (entries.isEmpty)
        pw.Text(
          'Nothing saved yet.',
          style: const pw.TextStyle(fontSize: 13, color: _dim),
        ),
    ];

    for (final (bookName, group) in _byBook(entries)) {
      body
        ..add(pw.SizedBox(height: 14))
        ..add(
          pw.Text(
            bookName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
        )
        ..add(pw.SizedBox(height: 8));

      final highlights = group
          .where((e) => e.kind == PdfKind.highlight)
          .toList();
      if (highlights.isNotEmpty) {
        body.add(_heading('Highlights'));
        for (final (hex, refs) in _groupedHighlights(highlights)) {
          body.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    margin: const pw.EdgeInsets.only(top: 1, right: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(
                        0xFF000000 | int.parse(hex, radix: 16),
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                      border: pw.Border.all(
                        color: const PdfColor(0, 0, 0, 0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      refs,
                      style: const pw.TextStyle(fontSize: 12, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      final notes = group.where((e) => e.kind == PdfKind.note).toList()
        ..sort(_byPlace);
      if (notes.isNotEmpty) {
        body.add(_heading('Notes', top: 4));
        for (final n in notes) {
          body
            ..add(
              pw.Text(
                n.reference,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
            )
            ..add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 2, bottom: 6),
                child: pw.Text(
                  n.text,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: _dim,
                  ),
                ),
              ),
            );
        }
      }

      for (final (heading, kind) in const [
        ('Bookmarks', PdfKind.bookmark),
        ('Favorites', PdfKind.favorite),
      ]) {
        final saved = group.where((e) => e.kind == kind).toList()
          ..sort(_byPlace);
        if (saved.isEmpty) continue;
        body.add(_heading(heading, top: 4));
        for (final b in saved) {
          body.add(
            pw.Text(
              b.reference,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
              ),
            ),
          );
          if (b.text.isNotEmpty) {
            body.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 2, bottom: 6),
                child: pw.Text(
                  b.text,
                  style: const pw.TextStyle(fontSize: 12, color: _ink),
                ),
              ),
            );
          }
        }
      }
    }

    final doc = pw.Document(theme: theme, title: title)
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(48),
          build: (_) => body,
        ),
      );
    return doc.save();
  }

  static pw.Widget _heading(String text, {double top = 0}) => pw.Padding(
    padding: pw.EdgeInsets.only(top: top, bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _dim,
      ),
    ),
  );

  static int _byPlace(PdfEntry a, PdfEntry b) => a.chapter != b.chapter
      ? a.chapter.compareTo(b.chapter)
      : a.verse.compareTo(b.verse);

  static List<(String, List<PdfEntry>)> _byBook(List<PdfEntry> entries) {
    final byBook = <String, List<PdfEntry>>{};
    final order = <String, int>{};
    for (final e in entries) {
      byBook.putIfAbsent(e.bookName, () => []).add(e);
      final o = order[e.bookName];
      order[e.bookName] = o == null || e.bookOrder < o ? e.bookOrder : o;
    }
    final names = byBook.keys.toList()
      ..sort((a, b) {
        final c = (order[a] ?? 999).compareTo(order[b] ?? 999);
        return c != 0 ? c : a.compareTo(b);
      });
    return [for (final n in names) (n, byBook[n]!)];
  }

  /// Highlights by color, presets first: (hex, "2:3, 3:14, 3:20-22").
  static List<(String, String)> _groupedHighlights(List<PdfEntry> hs) {
    final byHex = <String, List<PdfEntry>>{};
    for (final h in hs) {
      byHex
          .putIfAbsent(
            HighlightPalette.normalize(h.colorHex ?? 'FFD700') ?? 'FFD700',
            () => [],
          )
          .add(h);
    }
    final presets = [for (final p in HighlightPalette.presets) p.hex];
    final keys = byHex.keys.toList()
      ..sort((a, b) {
        final ia = presets.contains(a) ? presets.indexOf(a) : 999;
        final ib = presets.contains(b) ? presets.indexOf(b) : 999;
        return ia != ib ? ia.compareTo(ib) : a.compareTo(b);
      });
    return [for (final k in keys) (k, _compact(byHex[k]!))];
  }

  static String _compact(List<PdfEntry> es) {
    final pairs = {for (final e in es) (e.chapter, e.verse)}.toList()
      ..sort(
        (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
      );
    final out = <String>[];
    for (var i = 0; i < pairs.length;) {
      var j = i;
      while (j + 1 < pairs.length &&
          pairs[j + 1].$1 == pairs[i].$1 &&
          pairs[j + 1].$2 == pairs[j].$2 + 1) {
        j++;
      }
      out.add(
        j > i
            ? '${pairs[i].$1}:${pairs[i].$2}-${pairs[j].$2}'
            : '${pairs[i].$1}:${pairs[i].$2}',
      );
      i = j + 1;
    }
    return out.join(', ');
  }
}
