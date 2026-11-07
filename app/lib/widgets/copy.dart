import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies [text] and confirms with a snackbar; browsers may refuse clipboard
/// access, which gets its own message instead of an error.
Future<void> copyWithFeedback(BuildContext context, String text) async {
  final messenger = ScaffoldMessenger.of(context);
  String message;
  try {
    await Clipboard.setData(ClipboardData(text: text));
    message = 'Copied to clipboard';
  } on PlatformException {
    message = 'Your browser didn’t allow copying';
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
}
