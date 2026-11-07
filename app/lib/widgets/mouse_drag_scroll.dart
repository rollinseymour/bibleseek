import 'dart:ui';

import 'package:flutter/material.dart';

/// Lets a mouse drag scroll [child] too. Flutter web scrolls only by wheel and
/// touch by default, which leaves horizontal rails and pagers stuck for mouse users.
class MouseDragScroll extends StatelessWidget {
  const MouseDragScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(
      context,
    ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
    child: child,
  );
}
