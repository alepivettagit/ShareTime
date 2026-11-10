import 'package:flutter/material.dart';
import '../../core/utils/hash_utils.dart';

class AvatarPainter extends CustomPainter {
  final String seed;
  final Color color;
  final Color backgroundColor;

  AvatarPainter({
    required this.seed,
    required this.color,
    this.backgroundColor = const Color(0xFF131926),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(rrect, bgPaint);

    final hash = fnv1a32(seed);

    // Griglia 5x5: 15 bit determinano le prime 3 colonne (x=0, 1, 2)
    // Le colonne 3 e 4 sono specchiate (col 3 = col 1, col 4 = col 0)
    final grid = List.generate(5, (_) => List.generate(5, (_) => false));

    var bitIndex = 0;
    for (var col = 0; col < 3; col++) {
      for (var row = 0; row < 5; row++) {
        final isFilled = ((hash >> bitIndex) & 1) == 1;
        grid[col][row] = isFilled;
        // Specchiatura
        if (col == 0) grid[4][row] = isFilled;
        if (col == 1) grid[3][row] = isFilled;
        bitIndex++;
      }
    }

    final cubePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calcolo dimensioni e padding interno (12% padding perimetrale)
    final padding = size.width * 0.12;
    final availableSize = size.width - (padding * 2);
    final cellSize = availableSize / 5;
    final cubeRadius = Radius.circular(cellSize * 0.18);

    for (var col = 0; col < 5; col++) {
      for (var row = 0; row < 5; row++) {
        if (grid[col][row]) {
          final x = padding + (col * cellSize);
          final y = padding + (row * cellSize);
          final cubeRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 0.5, y + 0.5, cellSize - 1, cellSize - 1),
            cubeRadius,
          );
          canvas.drawRRect(cubeRect, cubePaint);
        }
      }
    }

    // Bordo sottile di rifinitura
    final borderPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
