import 'package:flutter/material.dart';

/// Small uppercase heading above a group of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.title, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 6),
  });

  final String title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    ),
  );
}
