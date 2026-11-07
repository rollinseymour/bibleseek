import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'annotations/annotation_store.dart';
import 'app/app_model.dart';
import 'app/root_shell.dart';
import 'bible/bible_library.dart';
import 'bible/bible_store.dart';
import 'data/prefs.dart';
import 'design/app_theme.dart';
import 'home/verse_search.dart';
import 'memory/memory_store.dart';
import 'more/auto_backups.dart';
import 'plans/plans.dart';
import 'reader/read_aloud.dart';
import 'settings/settings_model.dart';
import 'wordstudy/lexicon.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = Prefs(await SharedPreferences.getInstance());
  final store = BibleStore();
  AutoBackups.schedule(prefs);
  final BibleLibrary library;
  try {
    library = await BibleLibrary.load();
  } catch (_) {
    runApp(const _LoadFailed());
    return;
  }
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: prefs),
        Provider.value(value: library),
        Provider.value(value: store),
        Provider(create: (_) => WordStudyData(store)),
        Provider(create: (_) => VerseSearch(library)),
        ChangeNotifierProvider(create: (_) => AppModel()),
        ChangeNotifierProvider(create: (_) => SettingsModel(prefs)),
        ChangeNotifierProvider(create: (_) => AnnotationStore(prefs)),
        ChangeNotifierProvider(create: (_) => MemoryVerseStore(prefs)),
        ChangeNotifierProvider(create: (_) => PlanStore(prefs)),
        ChangeNotifierProvider(create: (_) => ReadAloudService(prefs)),
      ],
      child: const BibleSeekApp(),
    ),
  );
}

class BibleSeekApp extends StatelessWidget {
  const BibleSeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.select<SettingsModel, AppThemeKind>((s) => s.theme);
    return MaterialApp(
      title: 'Bible Seek',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(theme),
      home: const RootShell(),
    );
  }
}

/// Shown when the book index can't be fetched (offline on first visit).
class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(AppThemeKind.dark),
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bible Seek couldn’t load. Check your connection and reload the page.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
