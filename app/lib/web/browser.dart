import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Resolves a path against the page's `<base href>`, so content loads from
/// `/read/content/...` when the app is served under `/read/`.
Uri contentUri(String path) => Uri.parse(web.document.baseURI).resolve(path);

void downloadTextFile(
  String filename,
  String text, {
  String type = 'application/json',
}) {
  final blob = web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: type));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

/// Opens the browser's file chooser and returns the chosen file's text, or
/// null if the person cancels.
Future<String?> pickTextFile({String accept = '.json,application/json'}) {
  final done = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.addEventListener(
    'change',
    ((web.Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        if (!done.isCompleted) done.complete(null);
        return;
      }
      file.text().toDart.then(
        (t) => done.isCompleted ? null : done.complete(t.toDart),
        onError: (Object e) => done.isCompleted ? null : done.completeError(e),
      );
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!done.isCompleted) done.complete(null);
    }).toJS,
  );
  input.click();
  return done.future;
}

bool get canShareNatively => (web.window.navigator as JSObject).has('share');

/// The system share sheet where the browser has one (phones, Safari).
/// Returns false when unavailable or dismissed.
Future<bool> shareText(String text) async {
  if (!canShareNatively) return false;
  try {
    await web.window.navigator.share(web.ShareData(text: text)).toDart;
    return true;
  } catch (_) {
    return false;
  }
}
