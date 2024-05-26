import 'dart:ui';

import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double blurX;
  final double blurY;
  final Color tintColor;

  final BorderRadius clipBorderRadius;
  final Clip clipBehaviour;
  final TileMode tileMode;
  final CustomClipper<RRect>? clipper;

  const Glass({
    super.key,
    required this.child,
    this.enabled = true,
    this.blurX = 10.0,
    this.blurY = 10.0,
    this.tintColor = Colors.white,
    this.clipBorderRadius = BorderRadius.zero,
    this.clipBehaviour = Clip.antiAlias,
    this.tileMode = TileMode.clamp,
    this.clipper,
  });

  @override
  Widget build(BuildContext context) {
    return enabled
        ? ClipRRect(
            clipper: clipper,
            clipBehavior: clipBehaviour,
            borderRadius: clipBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurX,
                sigmaY: blurY,
                tileMode: tileMode,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: (tintColor != Colors.transparent)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tintColor.withOpacity(0.1),
                            tintColor.withOpacity(0.08),
                          ],
                        )
                      : null,
                ),
                child: child,
              ),
            ),
          )
        : child;
  }
}
