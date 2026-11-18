import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Standardized FinPocket Brand Logo Widget
/// Consistent across all screens: Splash, Auth, Headers, Drawer, and Dialogs.
class FinPocketLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final bool hasGlow;

  const FinPocketLogo({
    super.key,
    this.size = 58,
    this.showText = false,
    this.subtitle,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.26);
    final emojiSize = size * 0.52;

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: const Color(0x4010B981),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientPrimary,
              borderRadius: borderRadius,
            ),
            alignment: Alignment.center,
            child: Text(
              '💰',
              style: TextStyle(fontSize: emojiSize),
            ),
          ),
        ),
      ),
    );

    if (!showText) {
      return badge;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badge,
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.gradientPrimary.createShader(bounds),
          child: Text(
            'FinPocket',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
