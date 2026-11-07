import 'package:flutter/material.dart';

import '../widgets/page_header.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

/// Study tools and app settings. Tools not yet on the web are listed as
/// coming soon so the menu matches the iPhone app's.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _comingSoon = [
    ('Topics', Icons.layers_outlined),
    ('Reading Plans', Icons.calendar_month_outlined),
    ('Word Study', Icons.translate),
    ('Memory Verses', Icons.psychology_outlined),
    ('Channels', Icons.smart_display_outlined),
    ('Cross-References', Icons.link),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              children: [
                const PageHeader('More'),
                section('Study & tools'),
                for (final (title, icon) in _comingSoon)
                  ListTile(
                    enabled: false,
                    leading: Icon(icon),
                    title: Text(title),
                    trailing: const Text(
                      'Coming soon',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                section('App'),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
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
