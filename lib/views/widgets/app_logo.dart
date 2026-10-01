import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.24;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF82C82E),
            Color(0xFF67A922),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF75B928).withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.phone_fill,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}
