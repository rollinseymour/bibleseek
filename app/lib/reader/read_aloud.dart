import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../data/prefs.dart';
import '../design/reader_palette.dart';
import 'reader_model.dart';

enum ReadState { idle, playing, paused }

/// Reads the reader's chapter aloud with the browser's speech voices, verse by
/// verse, carrying on into the next chapter. Pausing stops the voice and
/// resuming restarts the current verse, which behaves the same in every browser.
class ReadAloudService extends ChangeNotifier {
  ReadAloudService(this._prefs) {
    if (supported) {
      _synth.addEventListener(
        'voiceschanged',
        ((web.Event _) => notifyListeners()).toJS,
      );
    }
  }

  final Prefs _prefs;

  static bool get supported => (web.window as JSObject).has('speechSynthesis');
  web.SpeechSynthesis get _synth => web.window.speechSynthesis;

  static const rates = [0.75, 1.0, 1.25, 1.5, 2.0];
  static const _rateKey = 'pref_read_aloud_rate';
  static const _followKey = 'pref_read_aloud_follow';

  /// Web voices aren't the iPhone's, so the choice is kept apart from `pref_read_aloud_voice`.
  static const _voiceKey = 'web_read_aloud_voice';

  static String rateLabel(double r) =>
      r == r.roundToDouble() ? '${r.toInt()}×' : '$r×';

  ReadState state = ReadState.idle;

  /// The verse being read, and the word within it (offsets into the verse's displayed text).
  int? verse;
  ({int start, int end})? word;

  ReaderModel? _model;
  String? _pageKey;
  List<int> _order = const [];
  Map<int, String> _text = const {};
  int _run = 0;

  /// Kept so the browser can't garbage-collect it before `end` fires.
  // ignore: unused_field
  web.SpeechSynthesisUtterance? _current;

  bool get isActive => state != ReadState.idle;

  double get rate {
    final r = _prefs.getDouble(_rateKey, 1);
    return rates.contains(r) ? r : 1;
  }

  bool get follow => _prefs.getBool(_followKey, true);
  set follow(bool v) {
    _prefs.setBool(_followKey, v);
    notifyListeners();
  }

  String get voiceUri => _prefs.getString(_voiceKey) ?? '';
  set voiceUri(String v) {
    _prefs.setString(_voiceKey, v);
    if (state == ReadState.playing && verse != null) _start(verse!);
    notifyListeners();
  }

  /// Installed voices, English first.
  List<web.SpeechSynthesisVoice> voices() {
    if (!supported) return const [];
    final all = _synth.getVoices().toDart;
    int rank(web.SpeechSynthesisVoice v) =>
        v.lang.toLowerCase().startsWith('en') ? 0 : 1;
    return all..sort(
      (a, b) =>
          rank(a) != rank(b) ? rank(a) - rank(b) : a.name.compareTo(b.name),
    );
  }

  web.SpeechSynthesisVoice? _voice() {
    final all = voices();
    final chosen = all.where((v) => v.voiceURI == voiceUri).firstOrNull;
    if (chosen != null) return chosen;
    return all
            .where(
              (v) => v.lang.toLowerCase().startsWith('en') && v.localService,
            )
            .firstOrNull ??
        all.where((v) => v.lang.toLowerCase().startsWith('en')).firstOrNull;
  }

  static String _key(ReaderModel m) =>
      '${m.version}|${m.bookCode}|${m.chapter}';

  bool isReading(ReaderModel m) => isActive && _pageKey == _key(m);

  String get reference =>
      _model == null ? '' : '${_model!.bookName} ${_model!.chapter}';

  bool _load(ReaderModel m) {
    final order = <int>[];
    final text = <int, String>{};
    for (final v in m.verses) {
      // Same length as the displayed text, so word offsets line up with it.
      final t = v.renderedBody.replaceAll('¶', ' ');
      if (t.trim().isEmpty) continue;
      order.add(v.number);
      text[v.number] = t;
    }
    if (order.isEmpty) return false;
    _model = m;
    _pageKey = _key(m);
    _order = order;
    _text = text;
    return true;
  }

  // MARK: controls

  /// Reads the chapter from [from], or from the top with the chapter announced.
  void play(ReaderModel m, {int? from}) {
    if (!_load(m)) return stop();
    final start = from == null
        ? _order.first
        : _order.firstWhere((v) => v >= from, orElse: () => _order.first);
    _start(start, announce: start == _order.first);
  }

  void pause() {
    if (state != ReadState.playing) return;
    _run++;
    _synth.cancel();
    state = ReadState.paused;
    word = null;
    notifyListeners();
  }

  void resume() {
    final m = _model;
    if (state != ReadState.paused || verse == null || m == null) return;
    if (_key(m) != _pageKey) return stop();
    _start(verse!);
  }

  void toggle() => state == ReadState.playing ? pause() : resume();

  void stop() {
    _run++;
    if (supported) _synth.cancel();
    state = ReadState.idle;
    verse = null;
    word = null;
    _pageKey = null;
    _current = null;
    notifyListeners();
  }

  void skip(int delta) {
    final v = verse;
    if (!isActive || v == null) return;
    final i = _order.indexOf(v) + delta;
    if (i >= _order.length) {
      if (state == ReadState.playing) _finishChapter();
      return;
    }
    final next = _order[i.clamp(0, _order.length - 1)];
    if (state == ReadState.playing) {
      _start(next);
    } else {
      verse = next;
      word = null;
      notifyListeners();
    }
  }

  void setRate(double r) {
    _prefs.setDouble(_rateKey, r);
    if (state == ReadState.playing && verse != null) _start(verse!);
    notifyListeners();
  }

  /// The reader changed page: a translation switch on the same chapter carries
  /// on from the current verse; any other move ends the reading.
  void readerMoved(ReaderModel m) {
    if (!isActive || _pageKey == _key(m) || m.loading) return;
    final old = _pageKey!.split('|');
    if (old[1] != m.bookCode || old[2] != '${m.chapter}' || !_load(m)) {
      return stop();
    }
    if (verse != null && !_order.contains(verse)) {
      verse = _order.firstWhere((v) => v > verse!, orElse: () => _order.last);
    }
    if (state == ReadState.playing && verse != null) {
      _start(verse!);
    } else {
      notifyListeners();
    }
  }

  /// A short sample of the chosen voice and speed.
  void preview() {
    if (!supported) return;
    pause();
    _synth.cancel();
    final u = web.SpeechSynthesisUtterance(
      'In the beginning God created the heaven and the earth.',
    )..rate = rate;
    final v = _voice();
    if (v != null) u.voice = v;
    _current = u;
    _synth.speak(u);
  }

  // MARK: speaking

  void _start(int v, {bool announce = false}) {
    final run = ++_run;
    _synth.cancel();
    verse = v;
    word = null;
    state = ReadState.playing;
    notifyListeners();
    // Some browsers drop an utterance queued in the same tick as cancel().
    Timer(const Duration(milliseconds: 60), () {
      if (run != _run) return;
      if (announce && _model != null) {
        _utter(
          '${_model!.bookName}, chapter ${_model!.chapter}.',
          run,
          null,
          () => _speakVerse(v, run),
        );
      } else {
        _speakVerse(v, run);
      }
    });
  }

  void _speakVerse(int v, int run) {
    if (run != _run) return;
    if (verse != v) {
      verse = v;
      word = null;
      notifyListeners();
    }
    _utter(_text[v] ?? '', run, v, () {
      final i = _order.indexOf(v);
      if (i + 1 < _order.length) {
        _speakVerse(_order[i + 1], run);
      } else {
        _finishChapter();
      }
    });
  }

  void _utter(String text, int run, int? forVerse, VoidCallback onDone) {
    final u = web.SpeechSynthesisUtterance(text)
      ..rate = rate
      ..lang = 'en-US';
    final voice = _voice();
    if (voice != null) u.voice = voice;
    u.onend = ((web.Event _) {
      if (run == _run && state == ReadState.playing) onDone();
    }).toJS;
    if (forVerse != null) {
      u.onboundary = ((web.SpeechSynthesisEvent e) {
        if (run != _run || e.name != 'word') return;
        final start = e.charIndex;
        var end = start + e.charLength;
        if (end <= start) {
          final m = RegExp(r'\S+').matchAsPrefix(text, start);
          end = m?.end ?? start;
        }
        word = (start: start, end: end);
        notifyListeners();
      }).toJS;
    }
    _current = u;
    _synth.speak(u);
  }

  /// Turns the page and keeps reading, as the iPhone app does.
  void _finishChapter() {
    final m = _model;
    if (m == null || !m.canGoNext) return stop();
    final run = ++_run;
    m.goNext();
    void listener() {
      if (m.loading || run != _run) return;
      m.removeListener(listener);
      if (!_load(m)) return stop();
      _start(_order.first, announce: true);
    }

    m.addListener(listener);
  }
}

/// The read-aloud controls floating over the reader.
class ReadAloudBar extends StatelessWidget {
  const ReadAloudBar({super.key, required this.palette});
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<ReadAloudService>();
    final fg = palette.isDark ? Colors.white : const Color(0xFF1A1A1A);
    Widget control(IconData icon, String label, VoidCallback onTap) =>
        IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, color: palette.accent),
        );
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: (palette.isDark ? const Color(0xFF2A2A2E) : Colors.white)
            .withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          control(Icons.skip_previous, 'Previous verse', () => audio.skip(-1)),
          Material(
            color: palette.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: audio.toggle,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  audio.state == ReadState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: palette.background,
                ),
              ),
            ),
          ),
          control(Icons.skip_next, 'Next verse', () => audio.skip(1)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    audio.state == ReadState.playing
                        ? 'Reading aloud'
                        : 'Paused',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    audio.verse == null
                        ? audio.reference
                        : '${audio.reference}:${audio.verse}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<double>(
            tooltip: 'Speed',
            initialValue: audio.rate,
            onSelected: audio.setRate,
            itemBuilder: (_) => [
              for (final r in ReadAloudService.rates)
                CheckedPopupMenuItem(
                  value: r,
                  checked: r == audio.rate,
                  child: Text(ReadAloudService.rateLabel(r)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ReadAloudService.rateLabel(audio.rate),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
          ),
          control(Icons.close, 'Stop reading', audio.stop),
        ],
      ),
    );
  }
}

/// The resting entry point: a round headphones button in the reader's corner.
class ListenButton extends StatelessWidget {
  const ListenButton({super.key, required this.palette, required this.onTap});
  final ReaderPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Listen to this chapter',
    child: Material(
      color: (palette.isDark ? const Color(0xFF2A2A2E) : Colors.white)
          .withValues(alpha: 0.94),
      shape: CircleBorder(
        side: BorderSide(color: palette.accent.withValues(alpha: 0.25)),
      ),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.headphones, color: palette.accent),
        ),
      ),
    ),
  );
}
