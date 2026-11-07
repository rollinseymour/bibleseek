import 'package:flutter/material.dart';

import '../bible/bible_store.dart';
import '../design/reader_palette.dart';
import 'reader_model.dart';

/// Reader chrome: the reference pill (book/chapter picker), go to verse,
/// fonts & settings, and the translation pill. While verses are selected it
/// becomes a "Selected: …" label.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({
    super.key,
    required this.model,
    required this.palette,
    required this.onReference,
    required this.onGoToVerse,
    required this.onSettings,
    required this.onChapterRelated,
    this.picking = false,
    this.onListen,
    this.onCancelPick,
    this.onConfirmPick,
    required this.interlinearOn,
    required this.onInterlinear,
    required this.interlinearReverse,
    required this.onInterlinearOrder,
  });

  final ReaderModel model;
  final ReaderPalette palette;
  final VoidCallback onReference;
  final VoidCallback onGoToVerse;
  final VoidCallback onSettings;
  final VoidCallback onChapterRelated;

  /// Share-card "Add other verses": Cancel, the reference pill, and Add (lit
  /// once verses are selected).
  final bool picking;

  /// Null where the browser can't speak.
  final VoidCallback? onListen;
  final VoidCallback? onCancelPick;
  final VoidCallback? onConfirmPick;

  /// Word-by-word Greek/Hebrew under each verse.
  final bool interlinearOn;
  final VoidCallback onInterlinear;

  /// Interlinear in English (KJV) word order instead of the original's.
  final bool interlinearReverse;
  final ValueChanged<bool> onInterlinearOrder;

  @override
  Widget build(BuildContext context) {
    final selecting = model.selected.isNotEmpty;
    return SizedBox(
      height: 54,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: picking
            ? _pickingChrome()
            : selecting
            ? _selectionLabel()
            : _chrome(context),
      ),
    );
  }

  Widget _pickingChrome() {
    final ready = model.selected.isNotEmpty;
    Widget pill(String text, Color fg, Color bg, VoidCallback? onTap) =>
        Material(
          color: bg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text(
                text,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
    return Padding(
      key: const ValueKey('picking'),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          pill(
            'Cancel',
            palette.accent,
            palette.accent.withValues(alpha: 0.12),
            onCancelPick,
          ),
          const Spacer(),
          pill(
            ready ? model.selectedReference : model.reference,
            palette.text,
            palette.accent.withValues(alpha: 0.12),
            onReference,
          ),
          const Spacer(),
          pill(
            'Add',
            ready ? palette.accent : palette.text.withValues(alpha: 0.3),
            ready
                ? palette.accent.withValues(alpha: 0.15)
                : palette.text.withValues(alpha: 0.08),
            ready ? onConfirmPick : null,
          ),
        ],
      ),
    );
  }

  Widget _selectionLabel() => Padding(
    key: const ValueKey('selected'),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Text(
            'Selected: ${model.selectedReference} ${model.version}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Clear selection (Esc)',
          onPressed: model.clearSelection,
          icon: Icon(Icons.close, color: palette.accent, size: 20),
        ),
      ],
    ),
  );

  Widget _chrome(BuildContext context) => Padding(
    key: const ValueKey('chrome'),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: palette.accent.withValues(alpha: 0.12),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onReference,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          model.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: palette.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _icon(Icons.search, 'Go to verse', onGoToVerse),
        const SizedBox(width: 8),
        _icon(Icons.text_fields, 'Fonts & settings', onSettings),
        const SizedBox(width: 8),
        Tooltip(
          message: interlinearOn
              ? 'Hide interlinear'
              : 'Show interlinear (Greek & Hebrew)',
          child: Material(
            color: interlinearOn
                ? palette.accent
                : palette.accent.withValues(alpha: 0.1),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onInterlinear,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.translate,
                  size: 18,
                  color: interlinearOn ? palette.background : palette.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<VoidCallback>(
          tooltip: 'More',
          onSelected: (action) => action(),
          itemBuilder: (_) => [
            if (onListen != null)
              PopupMenuItem(
                value: onListen,
                child: const ListTile(
                  leading: Icon(Icons.headphones),
                  title: Text('Listen to this chapter'),
                  dense: true,
                ),
              ),
            PopupMenuItem(
              value: onChapterRelated,
              child: const ListTile(
                leading: Icon(Icons.link),
                title: Text('Related in this chapter'),
                dense: true,
              ),
            ),
            if (interlinearOn) ...[
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: () => onInterlinearOrder(false),
                checked: !interlinearReverse,
                child: const Text('Original (Greek / Hebrew) order'),
              ),
              CheckedPopupMenuItem(
                value: () => onInterlinearOrder(true),
                checked: interlinearReverse,
                child: const Text('English (KJV) order'),
              ),
            ],
          ],
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.more_horiz, size: 18, color: palette.accent),
          ),
        ),
        const SizedBox(width: 8),
        _VersionPill(model: model, palette: palette),
      ],
    ),
  );

  Widget _icon(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
    message: tooltip,
    child: Material(
      color: palette.accent.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: palette.accent),
        ),
      ),
    ),
  );
}

/// Tap cycles translations; long-press or right-click lists them by full name.
class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.model, required this.palette});

  final ReaderModel model;
  final ReaderPalette palette;

  Future<void> _menu(BuildContext context, Offset at) async {
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        for (final v in BibleStore.versions)
          CheckedPopupMenuItem(
            value: v,
            checked: v == model.version,
            child: Text('$v — ${BibleStore.versionName(v)}'),
          ),
      ],
    );
    if (picked != null) model.switchVersion(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${BibleStore.versionName(model.version)}\nTap to switch · long-press or right-click for the list',
      child: GestureDetector(
        onLongPressStart: (d) => _menu(context, d.globalPosition),
        onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
        child: Material(
          color: Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: palette.accent.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () =>
                model.switchVersion(BibleStore.nextVersion(model.version)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                model.version,
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
