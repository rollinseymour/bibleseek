import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../reader/reader_model.dart';
import '../widgets/page_header.dart';

/// Home: continue reading and jump to any reference.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _go(BibleLibrary library, AppModel app) {
    final entered = _search.text.trim();
    if (entered.isEmpty) return;
    final t = library.parseReference(entered);
    if (t == null) {
      setState(
        () => _error =
            'Couldn’t find “$entered”. Try a reference like “John 3:16”.',
      );
      return;
    }
    setState(() => _error = null);
    _search.clear();
    app.open(t);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppModel>();
    final library = context.read<BibleLibrary>();
    final scheme = Theme.of(context).colorScheme;
    // Re-read on every visit: the reader saves its place as you go.
    final pos =
        ReadingPosition.load(context.read<Prefs>()) ?? ReadingPosition.fallback;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            children: [
              const PageHeader('Bible Seek'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Go to a verse — e.g. John 3:16',
                    errorText: _error,
                    filled: true,
                    fillColor: scheme.onSurface.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _go(library, app),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 0,
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => app.open(
                      ReaderTarget(
                        bookCode: pos.bookCode,
                        chapter: pos.chapter,
                        version: pos.version,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: scheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONTINUE READING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${library.name(pos.bookCode)} ${pos.chapter}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  BibleStore.versionName(pos.version),
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
