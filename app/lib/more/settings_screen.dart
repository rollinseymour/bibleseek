import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../design/app_theme.dart';
import '../design/reader_fonts.dart';
import '../design/reader_palette.dart';
import '../memory/memory_store.dart';
import '../plans/plans.dart';
import '../reader/read_aloud.dart';
import '../settings/settings_model.dart';
import '../web/browser.dart';
import '../web/offline.dart';
import 'auto_backups.dart';
import 'backup_service.dart';
import 'recently_deleted_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    final audio = context.watch<ReadAloudService>();
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
              if (ReadAloudService.supported) ...[
                section('Read Aloud'),
                ListTile(
                  title: const Text('Voice'),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value:
                          audio.voices().any(
                            (v) => v.voiceURI == audio.voiceUri,
                          )
                          ? audio.voiceUri
                          : '',
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Automatic'),
                        ),
                        for (final v in audio.voices())
                          DropdownMenuItem(
                            value: v.voiceURI,
                            child: Text(
                              '${v.name} (${v.lang})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => audio.voiceUri = v ?? '',
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Speed'),
                  trailing: DropdownButton<double>(
                    value: audio.rate,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final r in ReadAloudService.rates)
                        DropdownMenuItem(
                          value: r,
                          child: Text(ReadAloudService.rateLabel(r)),
                        ),
                    ],
                    onChanged: (r) => audio.setRate(r!),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Follow along'),
                  subtitle: const Text('Keeps the verse being read on screen.'),
                  value: audio.follow,
                  onChanged: (v) => audio.follow = v,
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Hear a sample'),
                  onTap: audio.preview,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    'Read Aloud uses the voices built into this browser and device. The iPhone app’s recorded voices aren’t available on the web.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
              if (OfflineBibles.supported) ...[
                section('Offline reading'),
                const _OfflineSection(),
              ],
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
                leading: const Icon(Icons.history),
                title: const Text('Automatic backups'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AutoBackupsScreen(),
                  ),
                ),
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

/// Save or remove each translation for reading without a connection.
class _OfflineSection extends StatelessWidget {
  const _OfflineSection();

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineBibles>();
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final usage = offline.usageBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final v in BibleStore.versions)
          ListTile(
            leading: SizedBox(
              width: 44,
              child: Text(
                v,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(BibleStore.versionName(v)),
            subtitle: offline.saving == v
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(
                      value: offline.total == 0
                          ? null
                          : offline.done / offline.total,
                    ),
                  )
                : offline.errors[v] != null
                ? Text(
                    offline.errors[v]!,
                    style: TextStyle(color: scheme.error),
                  )
                : Text(
                    offline.isSaved(v)
                        ? 'Saved on this device'
                        : 'About ${offline.megabytes(v)} MB',
                  ),
            trailing: offline.saving == v
                ? TextButton(onPressed: offline.stop, child: const Text('Stop'))
                : offline.isSaved(v)
                ? TextButton(
                    onPressed: () => offline.remove(v),
                    child: const Text('Remove'),
                  )
                : FilledButton.tonal(
                    onPressed: offline.saving == null
                        ? () => offline.save(v)
                        : null,
                    child: const Text('Save'),
                  ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'A saved Bible opens without a connection, along with search, topics and cross-references. '
            'Chapters you’ve read are kept too. Word Study and the interlinear need a connection for chapters '
            'you haven’t opened yet. Add this page to your home screen to open Bible Seek like an app.'
            '${usage == null ? '' : ' Bible Seek is using ${(usage / 1048576).toStringAsFixed(usage < 10485760 ? 1 : 0)} MB on this device.'}',
            style: TextStyle(fontSize: 12, height: 1.4, color: muted),
          ),
        ),
      ],
    );
  }
}
