import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final bool useCard;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
    this.useCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandPrimary, AppColors.brandAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: Center(
            child: Text(
              'C',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.5,
              ),
            ),
          ),
        );
      },
    );

    if (!useCard) {
      if (!showShadow) return imageWidget;
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withValues(alpha: 0.25),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    final borderRadius = size * 0.24;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Center(child: imageWidget),
    );
  }
}
