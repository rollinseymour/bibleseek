import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../design/reader_fonts.dart';
import '../settings/settings_model.dart';
import '../widgets/copy.dart';

/// One verse in every translation; each panel copies or opens in the reader.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  static const _examples = [
    'John 3:16',
    'Psalm 23:1',
    'Romans 8:28',
    'Philippians 4:13',
  ];
  final _input = TextEditingController();
  Timer? _debounce;
  ReaderTarget? _target;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(
          () => _target = context.read<BibleLibrary>().parseReference(
            _input.text,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final t = _target;
    final library = context.read<BibleLibrary>();
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _input,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _changed(),
                decoration: const InputDecoration(
                  labelText: 'Reference',
                  hintText: 'e.g. John 3:16, 1 Cor 13:4, Ps 23:1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (t != null && t.verse != null) ...[
                Text(
                  '${library.name(t.bookCode)} ${t.chapter}:${t.verse}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: muted),
                ),
                const SizedBox(height: 8),
                for (final v in BibleStore.versions) _panel(v, t),
              ] else if (_input.text.trim().isNotEmpty)
                Text(
                  'Enter a specific verse, e.g. “John 3:16”.',
                  style: TextStyle(color: muted),
                )
              else ...[
                Row(
                  children: [
                    Icon(Icons.compare_arrows, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'See one verse in all ${BibleStore.versions.length} translations',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Type a reference above — or start with one of these:',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ex in _examples)
                      ActionChip(
                        label: Text(ex),
                        onPressed: () {
                          _input.text = ex;
                          setState(() => _target = library.parseReference(ex));
                        },
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

  Widget _panel(String version, ReaderTarget t) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsModel>();
    final name = context.read<BibleLibrary>().name(t.bookCode);
    return Card(
      elevation: 0,
      color: scheme.onSurface.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
        child: FutureBuilder(
          future: context.read<BibleStore>().verseText(
            version,
            t.bookCode,
            t.chapter,
            t.verse!,
          ),
          builder: (context, snap) {
            final text = snap.data ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      version,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        BibleStore.versionName(version),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: text.isEmpty
                          ? null
                          : () => copyWithFeedback(
                              context,
                              '$name ${t.chapter}:${t.verse} ($version)\n$text',
                            ),
                    ),
                    IconButton(
                      tooltip: 'Open in reader',
                      icon: Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: scheme.primary,
                      ),
                      onPressed: () => context.read<AppModel>().open(
                        ReaderTarget(
                          bookCode: t.bookCode,
                          chapter: t.chapter,
                          verse: t.verse,
                          version: version,
                        ),
                      ),
                    ),
                  ],
                ),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (text.isEmpty)
                  Text(
                    'Verse text not available.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  )
                else
                  Text(
                    text,
                    style: readerTextStyle(
                      settings.readerFont,
                      fontSize: 16,
                      height: 1.5,
                      color: scheme.onSurface,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
