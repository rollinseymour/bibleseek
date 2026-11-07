import 'package:flutter/material.dart';

import '../memory/memory_screen.dart';
import '../study/compare_screen.dart';
import '../study/cross_references.dart';
import '../topics/topics_screen.dart';
import '../widgets/page_header.dart';
import '../wordstudy/word_study_screen.dart';
import '../widgets/section_label.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

/// Study tools and app settings, in the iPhone app's order. Tools not yet on
/// the web are listed as coming soon.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static final _tools = <(String, IconData, WidgetBuilder?)>[
    ('Topics', Icons.layers_outlined, (_) => const TopicsScreen()),
    ('Reading Plans', Icons.calendar_month_outlined, null),
    ('Word Study', Icons.translate, (_) => const WordStudyScreen()),
    (
      'Memory Verses',
      Icons.psychology_outlined,
      (_) => const MemoryVersesScreen(),
    ),
    ('Channels', Icons.smart_display_outlined, null),
    ('Compare', Icons.compare_arrows, (_) => const CompareScreen()),
    ('Cross-References', Icons.link, (_) => const CrossReferencesScreen()),
  ];

  static final _app = <(String, IconData, WidgetBuilder?)>[
    ('Settings', Icons.settings_outlined, (_) => const SettingsScreen()),
    ('About', Icons.info_outline, (_) => const AboutScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    Widget row((String, IconData, WidgetBuilder?) item) {
      final (title, icon, builder) = item;
      return ListTile(
        enabled: builder != null,
        leading: Icon(icon),
        title: Text(title),
        trailing: builder == null
            ? const Text('Coming soon', style: TextStyle(fontSize: 12))
            : const Icon(Icons.chevron_right),
        onTap: builder == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: builder),
              ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              children: [
                const PageHeader('More'),
                const SectionLabel('Study & tools'),
                for (final t in _tools) row(t),
                const SectionLabel('App'),
                for (final t in _app) row(t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
