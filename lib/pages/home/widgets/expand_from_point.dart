import 'package:flutter/material.dart';

class ExpandFromPointRoute extends PageRouteBuilder {
  final Widget page;
  final Offset tapPosition;

  ExpandFromPointRoute({required this.page, required this.tapPosition})
      : super(
    opaque: false, // Allows the background to show through for the blur
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Convert the screen pixel tap position into a Flutter Alignment (-1.0 to 1.0)
      final screenSize = MediaQuery.of(context).size;
      final alignX = (tapPosition.dx / screenSize.width) * 2 - 1;
      final alignY = (tapPosition.dy / screenSize.height) * 2 - 1;

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment(alignX, alignY),
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        ),
      );
    },
  );
}