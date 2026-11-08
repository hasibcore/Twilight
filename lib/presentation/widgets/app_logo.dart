import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String subtitle;
  final bool stackedSubtitle;

  const AppLogo({
    super.key,
    this.size = 38,
    this.showText = false,
    this.subtitle = 'MUSIC',
    this.stackedSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0722),
            borderRadius: BorderRadius.circular(size * 0.34),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B0764).withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.34),
            child: CustomPaint(
              size: Size(size, size),
              painter: const _TwilightLogoPainter(),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Flexible(
            child: stackedSubtitle
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Twilight',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Twilight',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
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

    // 1. Deep Dark Violet Background (#110926 -> #0A0518 -> #1A0B36)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF110926), Color(0xFF0A0518), Color(0xFF1A0B36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Inner Dark Circle (#0D0722)
    final innerCirclePaint = Paint()
      ..color = const Color(0xFF0D0722)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.32, innerCirclePaint);

    // 3. Outer Orbit Ring (#FF2A85 -> #9D4EDD -> #3A86FF)
    final orbitPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2A85), Color(0xFF9D4EDD), Color(0xFF3A86FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    canvas.drawCircle(center, w * 0.33, orbitPaint);

    // 4. Orbiting Pink Dot
    final dotPaint = Paint()
      ..color = const Color(0xFFFF2A85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.73, w * 0.36), w * 0.028, dotPaint);

    // 5. Inner Glowing Gradient Ring
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF3388),
          Color(0xFFF72585),
          Color(0xFF7209B7),
          Color(0xFF3A86FF),
          Color(0xFF4CC9F0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032;
    canvas.drawCircle(center, w * 0.255, ringPaint);

    // 6. Center Play Triangle (#FF4088 -> #D92588 -> #7209B7)
    final playPath = Path();
    playPath.moveTo(w * 0.43, w * 0.37);
    playPath.lineTo(w * 0.64, w * 0.50);
    playPath.lineTo(w * 0.43, w * 0.63);
    playPath.close();

    final playPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF4088), Color(0xFFD92588), Color(0xFF7209B7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(playPath, playPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
