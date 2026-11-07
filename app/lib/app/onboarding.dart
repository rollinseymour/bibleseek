import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../design/reader_fonts.dart';
import '../memory/memory_store.dart';
import '../more/backup_service.dart';
import '../plans/plans.dart';
import '../reader/reader_model.dart';
import '../settings/settings_model.dart';
import '../web/browser.dart';

/// First-run gate under the iPhone app's `pref_onboarding_done` key; anyone
/// with a reading position already (a restored backup) skips it.
class Onboarding {
  static const doneKey = 'pref_onboarding_done';

  static bool shouldShow(Prefs prefs) {
    if (prefs.getBool(doneKey, false)) return false;
    if (prefs.getString(ReadingPosition.key) != null) {
      prefs.setBool(doneKey, true);
      return false;
    }
    return true;
  }
}

/// Two pages: pick a Bible and a comfortable text size, then learn that notes
/// live in this browser, with a way to bring an iPhone backup across.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});
  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  String _version = 'KJV';
  String? _restored;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    final prefs = context.read<Prefs>();
    // A restored backup brings its own place; otherwise start at John 1.
    if (prefs.getString(ReadingPosition.key) == null) {
      ReadingPosition(_version, 'JHN', 'John', 1).save(prefs);
    }
    prefs.setBool(Onboarding.doneKey, true);
    widget.onFinish();
  }

  Future<void> _restore() async {
    final text = await pickTextFile();
    if (text == null || !mounted) return;
    final keys = BackupService.parse(text);
    if (keys == null) {
      setState(() => _restored = 'That file isn’t a Bible Seek backup.');
      return;
    }
    final n = BackupService.restore(context.read<Prefs>(), keys);
    context.read<SettingsModel>().reload();
    context.read<AnnotationStore>().reload();
    context.read<MemoryVerseStore>().reload();
    context.read<PlanStore>().reload();
    setState(() => _restored = 'Restored $n items from your backup.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.watch<SettingsModel>();
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                        children: [
                          Text(
                            'Welcome to Bible Seek',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pick the Bible you’d like to read. You can switch anytime.',
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 22),
                          for (final v in BibleStore.versions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: scheme.onSurface.withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _version == v
                                        ? scheme.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _version = v),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 52,
                                          child: Text(
                                            v,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            BibleStore.versionName(v),
                                          ),
                                        ),
                                        Icon(
                                          _version == v
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: _version == v
                                              ? scheme.primary
                                              : muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Text size',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'For God so loved the world, that he gave his only begotten Son…',
                            style: readerTextStyle(
                              s.readerFont,
                              fontSize: s.fontSize,
                              color: scheme.onSurface,
                            ),
                          ),
                          Slider(
                            value: s.fontSize,
                            min: SettingsModel.fontSizeMin,
                            max: SettingsModel.fontSizeMax,
                            divisions:
                                (SettingsModel.fontSizeMax -
                                        SettingsModel.fontSizeMin)
                                    .round(),
                            onChanged: (v) => s.fontSize = v,
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 56,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Your notes stay with you',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Highlights, notes and bookmarks are saved in this browser — nothing is sent to a server. '
                            'Back them up from Settings anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.45, color: muted),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Already use Bible Seek on iPhone?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'In the app, go to More › Settings › Back up my data, save the file, then open it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _restore,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Restore a backup'),
                            ),
                          ),
                          if (_restored != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                _restored!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.primary),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Container(
                        margin: const EdgeInsets.all(3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.18),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _page == 0
                          ? () => _pages.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : _finish,
                      child: Text(
                        _page == 0 ? 'Continue' : 'Get Started',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
