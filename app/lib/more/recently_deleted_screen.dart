import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';

/// Deleted highlights, notes, bookmarks and favorites, kept for 7 days.
class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key});

  static String _ago(int ms) {
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return d.inDays == 1 ? 'yesterday' : '${d.inDays} days ago';
  }

  static String _kind(TrashItem t) => switch (t.kind) {
    'bookmark' => 'Bookmark',
    'favorite' => 'Favorite',
    _ => switch (t.payload) {
      final List<Object?> l
          when l.isNotEmpty &&
              l.first is Map &&
              (l.first as Map).containsKey('note') =>
        'Note',
      _ => 'Highlight',
    },
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AnnotationStore>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: store.trash.isEmpty
              ? Center(
                  child: Text(
                    'Nothing deleted in the last 7 days.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView(
                  children: [
                    for (final t in store.trash)
                      ListTile(
                        title: Text(t.label),
                        subtitle: Text('${_kind(t)} · ${_ago(t.deletedAt)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => store.restoreTrash(t),
                              child: const Text('Restore'),
                            ),
                            IconButton(
                              tooltip: 'Delete forever',
                              icon: const Icon(Icons.delete_forever_outlined),
                              onPressed: () => store.purgeTrash(t),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
