import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bible/bible_store.dart';
import '../web/browser.dart';

/// A sermon or podcast from `videos.json`. Keywords are search-only.
class Video {
  const Video({
    required this.speakers,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.tags,
    required this.keywords,
  });

  factory Video.fromJson(Map<String, Object?> j) => Video(
    speakers: j['speakers'] as String? ?? j['speaker'] as String? ?? '',
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    youtubeUrl: j['youtubeUrl'] as String? ?? '',
    tags: (j['tags'] as List? ?? const []).whereType<String>().toList(),
    keywords: (j['keywords'] as List? ?? const []).whereType<String>().toList(),
  );

  final String speakers;
  final String title;
  final String description;
  final String youtubeUrl;
  final List<String> tags;
  final List<String> keywords;

  String? get videoId {
    final u = Uri.tryParse(youtubeUrl);
    if (u == null) return null;
    if (u.host.contains('youtu.be')) return u.pathSegments.firstOrNull;
    if (u.queryParameters['v'] case final v?) return v;
    final parts = u.pathSegments;
    if (parts.length >= 2 && (parts[0] == 'shorts' || parts[0] == 'embed')) {
      return parts[1];
    }
    return null;
  }

  String? get thumbnailUrl => videoId == null
      ? null
      : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Lower-cased searchable text.
  String get haystack =>
      '$title $speakers $description ${tags.join(' ')} ${keywords.join(' ')}'
          .toLowerCase();
}

/// A YouTube channel behind the app's videos.
class Channel {
  const Channel(this.name, this.url, this.icon);
  final String name;
  final String url;
  final String icon;
}

class VideosCatalog {
  static Future<({List<Video> sermons, List<Video> podcasts})>? _videos;
  static Future<List<Channel>>? _channels;

  static Future<({List<Video> sermons, List<Video> podcasts})> videos(
    BibleStore store,
  ) => _videos ??= () async {
    try {
      final raw = await store.data('videos.json') as Map<String, Object?>;
      List<Video> list(String k) => [
        for (final v
            in (raw[k] as List? ?? const []).whereType<Map<String, Object?>>())
          Video.fromJson(v),
      ];
      return (sermons: list('sermons'), podcasts: list('podcasts'));
    } catch (_) {
      _videos = null;
      rethrow;
    }
  }();

  /// Alphabetical, numbers first, ignoring case.
  static Future<List<Channel>> channels(BibleStore store) =>
      _channels ??= () async {
        try {
          final raw = await store.data('channels.json') as List;
          return [
            for (final c in raw.whereType<Map>())
              Channel(
                c['name'] as String? ?? '',
                c['url'] as String? ?? '',
                c['icon'] as String? ?? '',
              ),
          ]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        } catch (_) {
          _channels = null;
          rethrow;
        }
      }();
}

/// A YouTube image; their servers don't allow canvas reads, so Flutter falls
/// back to an `<img>` element.
Widget youtubeImage(
  String url, {
  required double width,
  required double height,
  Widget? placeholder,
}) => Image.network(
  url,
  width: width,
  height: height,
  fit: BoxFit.cover,
  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
  errorBuilder: (_, _, _) =>
      placeholder ?? SizedBox(width: width, height: height),
);

/// Every channel behind the app's videos; tap to open it on YouTube.
class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: FutureBuilder(
        future: VideosCatalog.channels(context.read<BibleStore>()),
        builder: (context, snap) {
          final channels = snap.data;
          if (channels == null) {
            return Center(
              child: snap.hasError
                  ? const Text('Couldn’t load channels.')
                  : const CircularProgressIndicator(),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: channels.length,
                itemBuilder: (context, i) {
                  final ch = channels[i];
                  final initials = ch.name
                      .split(' ')
                      .where((w) => w.isNotEmpty)
                      .take(2)
                      .map((w) => w[0])
                      .join()
                      .toUpperCase();
                  final fallback = CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary.withValues(alpha: 0.18),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  );
                  return ListTile(
                    onTap: () => openExternal(ch.url),
                    leading: ClipOval(
                      child: ch.icon.isEmpty
                          ? fallback
                          : youtubeImage(
                              ch.icon,
                              width: 48,
                              height: 48,
                              placeholder: fallback,
                            ),
                    ),
                    title: Text(
                      ch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
