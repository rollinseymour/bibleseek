import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _sections = [
    (
      'Scripture',
      'King James Version (1611), American Standard Version (1901), Berean Standard Bible, and World English Bible — '
          'all in the public domain. Source text adapted from eBible.org’s and Berean.Bible’s open distributions. '
          'Section headings are from the Berean Standard Bible.',
    ),
    (
      'Your data',
      'Bible Seek on the web keeps your highlights, notes, bookmarks, and settings in this browser only. Nothing is sent '
          'to a server. Clearing this site’s data erases them, so use Settings › Back up my data to keep a copy — the '
          'backup file also restores into the iPhone app.',
    ),
    (
      'Fonts',
      'Reader fonts are Source Serif 4, Gelasio, Nunito Sans, and Inter, under the SIL Open Font License, loaded from '
          'Google Fonts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bible Seek',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Web edition'),
              for (final (title, body) in _sections) ...[
                const SizedBox(height: 24),
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: text.bodyMedium?.copyWith(height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
