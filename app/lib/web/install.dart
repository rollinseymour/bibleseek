import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'browser.dart';

const appStoreUrl = 'https://apps.apple.com/app/id6760152974';

/// Already opened from the home screen or as an installed app.
bool get isInstalledApp =>
    web.window.matchMedia('(display-mode: standalone)').matches ||
    (web.window.navigator as JSObject)['standalone'] == true.toJS;

bool get _isApple {
  final ua = web.window.navigator.userAgent;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);
}

/// Chrome and Edge's install offer, which index.html holds back until the
/// person asks for it.
JSObject? get _installPrompt =>
    (web.window as JSObject)['bibleSeekInstall'] as JSObject?;

/// Installs straight away where the browser allows it; otherwise explains how,
/// pointing iPhone and iPad users at the App Store.
Future<void> installApp(BuildContext context) async {
  final prompt = _installPrompt;
  if (prompt != null) {
    (web.window as JSObject)['bibleSeekInstall'] = null;
    try {
      await (prompt.callMethod<JSPromise>('prompt'.toJS)).toDart;
      return;
    } catch (_) {
      // Already used; fall through to the instructions.
    }
  }
  if (!context.mounted) return;
  final apple = _isApple;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(apple ? 'Bible Seek on the App Store' : 'Install Bible Seek'),
      content: Text(
        apple
            ? 'Bible Seek is in the App Store, with recorded voices, reminders and a home screen widget. '
                  'To keep reading here instead, tap Share, then Add to Home Screen.'
            : 'Open your browser’s menu and choose Install app or Add to Home screen. On a computer, '
                  'Chrome and Edge have an install button in the address bar, and Safari has File › Add to Dock.',
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        if (apple)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openExternal(appStoreUrl);
            },
            child: const Text('Open the App Store'),
          ),
      ],
    ),
  );
}
