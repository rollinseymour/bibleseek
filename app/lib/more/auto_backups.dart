import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../annotations/annotation_store.dart';
import '../data/prefs.dart';
import '../memory/memory_store.dart';
import '../plans/plans.dart';
import '../settings/settings_model.dart';
import 'backup_service.dart';

/// A daily snapshot of everything Back up exports, newest seven kept. Stored
/// outside the `flutter.` keys so backups never contain backups. It lives in
/// this browser too, so it guards against mistakes in the app, not against
/// clearing the site's data.
class AutoBackups {
  static const _key = 'bibleseek.autobackups';
  static const keep = 7;

  static List<({String date, String json})> list() {
    try {
      final raw = web.window.localStorage.getItem(_key);
      if (raw == null) return const [];
      return [
        for (final o in (jsonDecode(raw) as List).whereType<Map>())
          if (o['date'] is String && o['json'] is String)
            (date: o['date'] as String, json: o['json'] as String),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Writes today's snapshot if there isn't one yet; on a full storage quota,
  /// keeps fewer snapshots rather than failing.
  static void snapshotIfDue(Prefs prefs) {
    final today = _today();
    final all = list();
    if (all.any((s) => s.date == today) || prefs.keys.isEmpty) return;
    var kept = [
      (date: today, json: BackupService.export(prefs)),
      ...all,
    ].take(keep).toList();
    while (kept.isNotEmpty) {
      try {
        web.window.localStorage.setItem(
          _key,
          jsonEncode([
            for (final s in kept) {'date': s.date, 'json': s.json},
          ]),
        );
        return;
      } catch (_) {
        kept = kept.sublist(0, kept.length - 1);
      }
    }
  }

  /// Snapshots on startup and whenever the tab goes into the background.
  static void schedule(Prefs prefs) {
    snapshotIfDue(prefs);
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event _) {
        if (web.document.visibilityState == 'hidden') snapshotIfDue(prefs);
      }).toJS,
    );
  }
}

/// The daily snapshots, each restorable.
class AutoBackupsScreen extends StatefulWidget {
  const AutoBackupsScreen({super.key});

  @override
  State<AutoBackupsScreen> createState() => _AutoBackupsScreenState();
}

class _AutoBackupsScreenState extends State<AutoBackupsScreen> {
  Future<void> _restore(({String date, String json}) s) async {
    final keys = BackupService.parse(s.json);
    if (keys == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore ${s.date}?'),
        content: const Text(
          'Highlights, notes, bookmarks, plans and settings in that snapshot replace what’s here now.',
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
    if (ok != true || !mounted) return;
    final n = BackupService.restore(context.read<Prefs>(), keys);
    context.read<SettingsModel>().reload();
    context.read<AnnotationStore>().reload();
    context.read<MemoryVerseStore>().reload();
    context.read<PlanStore>().reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Restored $n items.')));
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = AutoBackups.list();
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(title: const Text('Automatic backups')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Bible Seek keeps a snapshot of your data each day you use it, the newest ${AutoBackups.keep}. '
                  'They’re stored in this browser, so to keep a copy elsewhere use Back up my data.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: muted),
                ),
              ),
              if (snapshots.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No snapshots yet.'),
                )
              else
                for (final s in snapshots)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(s.date),
                    subtitle: Text(
                      '${(s.json.length / 1024).toStringAsFixed(1)} KB',
                    ),
                    trailing: TextButton(
                      onPressed: () => _restore(s),
                      child: const Text('Restore'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
