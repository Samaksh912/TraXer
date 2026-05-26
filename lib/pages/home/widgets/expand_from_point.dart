import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';

class ExpandFromPointRoute extends PageRouteBuilder {
  final Widget page;
  final Offset tapPosition;

  ExpandFromPointRoute({required this.page, required this.tapPosition})
      : super(
    opaque: false,
    // Slightly faster for a snappier, lightweight feel
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final screenSize = MediaQuery.of(context).size;
      final alignX = (tapPosition.dx / screenSize.width) * 2 - 1;
      final alignY = (tapPosition.dy / screenSize.height) * 2 - 1;

      // easeOutExpo gives that premium "fast start, smooth glide to stop" feel
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutExpo,
        reverseCurve: Curves.easeInCubic,
      );

      return Stack(
        children: [
          // 1. The Blur Background: FADES ONLY (This fixes the lag completely)
          FadeTransition(
            opacity: curvedAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: context.appColors.background.withOpacity(0.6)),
            ),
          ),
          // 2. The Foreground Content: SCALES AND FADES
          FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              alignment: Alignment(alignX, alignY),
              scale: curvedAnimation,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}