import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../annotations/highlight_palette.dart';
import '../design/reader_palette.dart';
import '../widgets/mouse_drag_scroll.dart';

/// The floating annotation panel shown while verses are selected: three
/// swipeable pages (Highlight / Study / Keep) whose indicator names the active
/// page for a few seconds. Swipe down dismisses.
class SelectionPanel extends StatefulWidget {
  const SelectionPanel({
    super.key,
    required this.palette,
    required this.single,
    required this.favorite,
    required this.bookmarked,
    required this.onHighlight,
    required this.onMoreColors,
    required this.onMemorize,
    required this.onCompare,
    required this.onRelated,
    required this.onFavorite,
    required this.onBookmark,
    required this.onNote,
    required this.onCopy,
    required this.onShare,
    required this.onDismiss,
  });

  final ReaderPalette palette;
  final bool single;
  final bool favorite;
  final bool bookmarked;
  final ValueChanged<String?> onHighlight;
  final VoidCallback onMoreColors;
  final VoidCallback onMemorize;
  final VoidCallback onCompare;
  final VoidCallback onRelated;
  final VoidCallback onFavorite;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onDismiss;

  @override
  State<SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<SelectionPanel> {
  static const _pages = ['Highlight', 'Study', 'Keep'];
  final _controller = PageController();
  int _page = 0;
  bool _named = true;
  Timer? _nameTimer;

  @override
  void initState() {
    super.initState();
    _nameSoon();
  }

  void _nameSoon() {
    _nameTimer?.cancel();
    _named = true;
    _nameTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _named = false);
    });
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _fg =>
      widget.palette.isDark ? Colors.white : const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final dark = widget.palette.isDark;
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 150) widget.onDismiss();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: (dark ? const Color(0xFF2A2A2E) : Colors.white).withValues(
                alpha: 0.86,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _fg.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 6),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _fg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: MouseDragScroll(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (i) => setState(() {
                        _page = i;
                        _nameSoon();
                      }),
                      children: [_highlightPage(), _studyPage(), _keepPage()],
                    ),
                  ),
                ),
                _indicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicator() => SizedBox(
    height: 22,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _pages.length; i++)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              ),
              child: Container(
                constraints: const BoxConstraints(minWidth: 24),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: i == _page && _named
                      ? Text(
                          _pages[i],
                          key: ValueKey('t$i'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _fg.withValues(alpha: 0.6),
                          ),
                        )
                      : Container(
                          key: ValueKey('d$i'),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _fg.withValues(
                              alpha: i == _page ? 0.55 : 0.25,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _highlightPage() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _swatch(
        tooltip: 'Remove highlight',
        onTap: () => widget.onHighlight(null),
        child: CustomPaint(
          size: const Size(32, 32),
          painter: _RemovePainter(_fg),
        ),
      ),
      for (final s in HighlightPalette.presets)
        _swatch(
          tooltip: '${s.name} highlight',
          onTap: () => widget.onHighlight(s.hex),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: s.color,
              shape: BoxShape.circle,
              border: Border.all(color: _fg.withValues(alpha: 0.15)),
            ),
          ),
        ),
      _swatch(
        tooltip: 'More highlight colors',
        onTap: widget.onMoreColors,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Colors.yellow,
                Colors.orange,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.green,
                Colors.yellow,
              ],
            ),
            border: Border.all(color: _fg.withValues(alpha: 0.15)),
          ),
        ),
      ),
    ],
  );

  Widget _swatch({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) => Tooltip(
    message: tooltip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.5),
          child: child,
        ),
      ),
    ),
  );

  Widget _studyPage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        _cell(Icons.psychology_outlined, 'Memorize', widget.onMemorize),
        _cell(
          Icons.compare_arrows,
          'Compare',
          widget.onCompare,
          enabled: widget.single,
        ),
        _cell(Icons.link, 'Related', widget.onRelated, enabled: widget.single),
      ],
    ),
  );

  Widget _keepPage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        _cell(
          widget.favorite ? Icons.favorite : Icons.favorite_border,
          'Favorite',
          widget.onFavorite,
          tint: widget.favorite ? Colors.red : null,
        ),
        _cell(
          widget.bookmarked ? Icons.bookmark : Icons.bookmark_border,
          'Save',
          widget.onBookmark,
        ),
        _cell(Icons.sticky_note_2_outlined, 'Note', widget.onNote),
        _cell(Icons.copy, 'Copy', widget.onCopy),
        _cell(Icons.ios_share, 'Share', widget.onShare),
      ],
    ),
  );

  Widget _cell(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool enabled = true,
    Color? tint,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Tooltip(
          message: enabled ? title : 'Select a single verse to use',
          child: Material(
            color: _fg.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: tint ?? _fg),
                    const SizedBox(height: 3),
                    Text(title, style: TextStyle(fontSize: 11, color: _fg)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RemovePainter extends CustomPainter {
  _RemovePainter(this.fg);
  final Color fg;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      size.width / 2 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = fg.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      c + const Offset(-9.5, 9.5),
      c + const Offset(9.5, -9.5),
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(_RemovePainter old) => old.fg != fg;
}
