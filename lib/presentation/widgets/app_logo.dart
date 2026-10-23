import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 38,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              AssetPaths.logo,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CustomPaint(
                size: Size(size, size),
                painter: const _TwilightLogoPainter(),
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Twilight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'MUSIC',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TwilightLogoPainter extends CustomPainter {
  const _TwilightLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final w = size.width;

    // 1. Dark indigo/purple rounded background (Matching TwilightLogo.tsx)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF110926), Color(0xFF0A0518), Color(0xFF1A0B36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.28));
    canvas.drawRRect(rrect, bgPaint);

    // 2. Concentric ring gradient
    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF3388),
          Color(0xFFF72585),
          Color(0xFF7209B7),
          Color(0xFF3A86FF),
          Color(0xFF4CC9F0),
          Color(0xFFFF3388),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.35))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08;

    canvas.drawCircle(center, w * 0.28, ringPaint);

    // 3. Orbit satellite dot
    final dotPaint = Paint()..color = const Color(0xFFFF2A85);
    canvas.drawCircle(
        Offset(center.dx + w * 0.25, center.dy - w * 0.22), w * 0.035, dotPaint);

    // 4. Center Play triangle gradient
    final playPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF4088), Color(0xFFD92588), Color(0xFF7209B7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.2))
      ..style = PaintingStyle.fill;

    final playPath = Path();
    final pW = w * 0.16;
    final pH = w * 0.2;
    playPath.moveTo(center.dx - pW * 0.4, center.dy - pH * 0.5);
    playPath.lineTo(center.dx + pW * 0.65, center.dy);
    playPath.lineTo(center.dx - pW * 0.4, center.dy + pH * 0.5);
    playPath.close();

    canvas.drawPath(playPath, playPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
