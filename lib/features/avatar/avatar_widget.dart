import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'avatar_painter.dart';

class AvatarWidget extends StatelessWidget {
  final String seed;
  final String colorHex;
  final double size;
  final VoidCallback? onTap;
  final bool showGlow;

  const AvatarWidget({
    super.key,
    required this.seed,
    required this.colorHex,
    this.size = 40.0,
    this.onTap,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.parseHex(colorHex);

    Widget avatar = CustomPaint(
      size: Size(size, size),
      painter: AvatarPainter(
        seed: seed.isEmpty ? 'sharetime' : seed,
        color: color,
      ),
    );

    if (showGlow) {
      avatar = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.26),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
