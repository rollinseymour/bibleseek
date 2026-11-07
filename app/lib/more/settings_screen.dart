import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../data/prefs.dart';
import '../design/app_theme.dart';
import '../design/reader_fonts.dart';
import '../design/reader_palette.dart';
import '../memory/memory_store.dart';
import '../plans/plans.dart';
import '../settings/settings_model.dart';
import '../web/browser.dart';
import 'backup_service.dart';
import 'recently_deleted_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    final scheme = Theme.of(context).colorScheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
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
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              section('Appearance'),
              ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<AppThemeKind>(
                  value: s.theme,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final t in AppThemeKind.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (t) => s.theme = t!,
                ),
              ),
              section('Reader'),
              ListTile(
                title: const Text('Reader theme'),
                trailing: DropdownButton<String>(
                  value: s.readerTheme,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final k in SettingsModel.readerThemeOptions)
                      DropdownMenuItem(
                        value: k,
                        child: Text(ReaderPalette.resolve(k, s.theme).label),
                      ),
                  ],
                  onChanged: (k) => s.readerTheme = k!,
                ),
              ),
              ListTile(
                title: const Text('Reader font'),
                trailing: DropdownButton<String>(
                  value: s.readerFont,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final f in readerFontOptions)
                      DropdownMenuItem(
                        value: f,
                        child: Text(readerFontLabel(f)),
                      ),
                  ],
                  onChanged: (f) => s.readerFont = f!,
                ),
              ),
              ListTile(
                title: const Text('Font size'),
                trailing: Text('${s.fontSize.round()} pt'),
              ),
              Slider(
                value: s.fontSize,
                min: SettingsModel.fontSizeMin,
                max: SettingsModel.fontSizeMax,
                divisions:
                    (SettingsModel.fontSizeMax - SettingsModel.fontSizeMin)
                        .round(),
                onChanged: (v) => s.fontSize = v,
              ),
              SwitchListTile(
                title: const Text('Red-letter (words of Jesus)'),
                value: s.redLetter,
                onChanged: (v) => s.redLetter = v,
              ),
              SwitchListTile(
                title: const Text('Paragraph mode'),
                value: s.paragraphMode,
                onChanged: (v) => s.paragraphMode = v,
              ),
              SwitchListTile(
                title: const Text('Show cross-version annotations'),
                value: s.showCrossVersionAnnotations,
                onChanged: (v) => s.showCrossVersionAnnotations = v,
              ),
              section('Data'),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Back up my data'),
                onTap: () => _backup(context),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Restore from backup'),
                onTap: () => _restoreFromFile(context),
              ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Paste a backup'),
                onTap: () => _restoreFromPaste(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore_from_trash_outlined),
                title: const Text('Recently deleted'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RecentlyDeletedScreen(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Your highlights, notes, bookmarks, and settings are stored in this browser only. Clearing site data '
                  'erases them. A backup file restores here or into the Bible Seek iPhone app.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _backup(BuildContext context) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    downloadTextFile(
      'BibleSeek-Backup-${now.year}-${two(now.month)}-${two(now.day)}.json',
      BackupService.export(context.read<Prefs>()),
    );
  }

  Future<void> _restoreFromFile(BuildContext context) async {
    final text = await pickTextFile();
    if (text == null || !context.mounted) return;
    await _restore(context, text);
  }

  Future<void> _restoreFromPaste(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste a backup'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Paste the Bible Seek backup (JSON) here',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await _restore(context, text);
  }

  Future<void> _restore(BuildContext context, String text) async {
    final keys = BackupService.parse(text);
    if (keys == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore'),
          content: const Text('That doesn’t look like a Bible Seek backup.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This restores ${keys.length} items. Anything in this browser that the backup also contains — '
          'highlights, notes, bookmarks, settings — is replaced by the backup’s version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final n = BackupService.restore(context.read<Prefs>(), keys);
    context.read<SettingsModel>().reload();
    context.read<AnnotationStore>().reload();
    context.read<MemoryVerseStore>().reload();
    context.read<PlanStore>().reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Restored $n items.')));
  }
}
