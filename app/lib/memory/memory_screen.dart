import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../design/reader_fonts.dart';
import '../reader/reader_model.dart';
import '../settings/settings_model.dart';
import 'memory_store.dart';

/// Active and memorized verses. Tap an active verse to practice it.
class MemoryVersesScreen extends StatelessWidget {
  const MemoryVersesScreen({super.key});

  String _reference(BuildContext context, MemoryVerse v) =>
      '${context.read<BibleLibrary>().name(v.bookCode)} ${v.chapter}:${v.verse}';

  void _open(BuildContext context, MemoryVerse v) =>
      context.read<AppModel>().open(
        ReaderTarget(
          bookCode: v.bookCode,
          chapter: v.chapter,
          verse: v.verse,
          version: v.version,
        ),
      );

  Future<void> _add(BuildContext context) async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) {
          Future<void> add() async {
            final library = context.read<BibleLibrary>();
            final t = library.parseReference(controller.text);
            if (t == null || t.verse == null) {
              setLocal(
                () => error =
                    'Couldn’t recognize “${controller.text.trim()}”. Try a reference like John 3:16.',
              );
              return;
            }
            final version =
                ReadingPosition.load(context.read())?.version ?? 'KJV';
            String text;
            try {
              text = await context.read<BibleStore>().verseText(
                version,
                t.bookCode,
                t.chapter,
                t.verse!,
              );
            } catch (_) {
              text = '';
            }
            if (text.isEmpty) {
              setLocal(
                () => error =
                    'That verse wasn’t found — check the chapter and verse number.',
              );
              return;
            }
            if (!context.mounted) return;
            context.read<MemoryVerseStore>().add(
              version: version,
              bookCode: t.bookCode,
              chapter: t.chapter,
              verse: t.verse!,
              text: text,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }

          return AlertDialog(
            title: const Text('Add memory verse'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Reference (e.g. John 3:16)',
                helperText: 'Adds the verse in your current translation.',
                errorText: error,
                errorMaxLines: 2,
              ),
              onSubmitted: (_) => add(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: add, child: const Text('Add')),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MemoryVerseStore>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memory Verses'),
          actions: [
            IconButton(
              tooltip: 'Add a verse',
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Active (${store.active.length})'),
              Tab(text: 'Memorized (${store.archived.length})'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: TabBarView(
              children: [
                _list(
                  context,
                  store.active,
                  empty: (
                    Icons.psychology_outlined,
                    'No verses to memorize',
                    'Tap + to add a verse, or use “Memorize” from the reader.',
                  ),
                  actions: (v) => [
                    (
                      'Open in reader',
                      Icons.menu_book_outlined,
                      () => _open(context, v),
                    ),
                    (
                      'Mark memorized',
                      Icons.check,
                      () => store.markMemorized(v.id),
                    ),
                    (
                      'Remove',
                      Icons.delete_outline,
                      () => store.removeActive(v.id),
                    ),
                  ],
                ),
                _list(
                  context,
                  store.archived,
                  memorized: true,
                  empty: (
                    Icons.verified_outlined,
                    'Nothing memorized yet',
                    'Verses you finish practicing land here.',
                  ),
                  actions: (v) => [
                    (
                      'Open in reader',
                      Icons.menu_book_outlined,
                      () => _open(context, v),
                    ),
                    ('Relearn', Icons.undo, () => store.relearn(v.id)),
                    (
                      'Remove',
                      Icons.delete_outline,
                      () => store.removeArchived(v.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<MemoryVerse> verses, {
    bool memorized = false,
    required (IconData, String, String) empty,
    required List<(String, IconData, VoidCallback)> Function(MemoryVerse)
    actions,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsModel>();
    if (verses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                empty.$1,
                size: 44,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(empty.$2, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                empty.$3,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: verses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = verses[i];
        return ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MemoryDrillScreen(
                verse: v,
                reference: _reference(context, v),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                _reference(context, v),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              if (memorized)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.verified, size: 16, color: Colors.green),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                v.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: readerTextStyle(
                  settings.readerFont,
                  fontSize: 15,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (!memorized)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tap to practice',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),
          trailing: PopupMenuButton<VoidCallback>(
            tooltip: 'More',
            onSelected: (f) => f(),
            itemBuilder: (_) => [
              for (final (label, icon, action) in actions(v))
                PopupMenuItem(
                  value: action,
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    dense: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Active recall: the verse shows as blanks and its words are shuffled into a
/// bank. Picking words in order fills the blanks; a wrong pick shakes.
/// Finishing marks the verse memorized.
class MemoryDrillScreen extends StatefulWidget {
  const MemoryDrillScreen({
    super.key,
    required this.verse,
    required this.reference,
  });
  final MemoryVerse verse;
  final String reference;

  @override
  State<MemoryDrillScreen> createState() => _MemoryDrillScreenState();
}

class _MemoryDrillScreenState extends State<MemoryDrillScreen> {
  late final List<String> _words = widget.verse.text
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  late List<({int id, String text})> _bank;
  int _filled = 0;
  bool _showFull = false;
  bool _completed = false;
  int? _shaking;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _bank = _shuffled();
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    super.dispose();
  }

  List<({int id, String text})> _shuffled() =>
      [for (final (i, w) in _words.indexed) (id: i, text: w)]
        ..shuffle(Random());

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');

  void _tap(({int id, String text}) c) {
    if (_completed || _filled >= _words.length) return;
    if (_normalize(c.text) == _normalize(_words[_filled])) {
      setState(() {
        _bank.removeWhere((b) => b.id == c.id);
        _filled++;
        _completed = _filled >= _words.length;
      });
      if (_completed) _complete();
    } else {
      _shakeTimer?.cancel();
      setState(() => _shaking = c.id);
      _shakeTimer = Timer(const Duration(milliseconds: 320), () {
        if (mounted) setState(() => _shaking = null);
      });
    }
  }

  Future<void> _complete() async {
    context.read<MemoryVerseStore>().markMemorized(widget.verse.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Memorized! 🎉'),
        content: Text(
          'You filled in every word of ${widget.reference} correctly. It’s now in your Memorized tab.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reference),
        actions: [
          IconButton(
            tooltip: 'Start over',
            onPressed: _completed
                ? null
                : () => setState(() {
                    _filled = 0;
                    _bank = _shuffled();
                  }),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: _showFull ? 'Hide verse' : 'Show verse',
            onPressed: _completed
                ? null
                : () => setState(() => _showFull = !_showFull),
            icon: Icon(_showFull ? Icons.visibility_off : Icons.visibility),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _words.isEmpty ? 0 : _filled / _words.length,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: _showFull
                          ? Text(
                              widget.verse.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.6,
                                fontStyle: FontStyle.italic,
                                color: scheme.onSurface.withValues(alpha: 0.85),
                              ),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  for (final (i, w) in _words.indexed)
                                    i < _filled
                                        ? TextSpan(
                                            text: '$w ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : TextSpan(
                                            text:
                                                '${'_' * max(1, w.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '').length)} ',
                                            style: TextStyle(
                                              color: i == _filled
                                                  ? scheme.primary
                                                  : muted,
                                              fontWeight: i == _filled
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, height: 1.6),
                            ),
                    ),
                  ),
                ),
                if (_completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Verse complete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _bank)
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 90),
                            offset: Offset(_shaking == c.id ? 0.08 : 0, 0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _shaking == c.id
                                    ? Colors.red
                                    : scheme.onSurface,
                                backgroundColor:
                                    (_shaking == c.id
                                            ? Colors.red
                                            : scheme.primary)
                                        .withValues(alpha: 0.08),
                                side: BorderSide(
                                  color:
                                      (_shaking == c.id
                                              ? Colors.red
                                              : scheme.primary)
                                          .withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _tap(c),
                              child: Text(c.text),
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
}
