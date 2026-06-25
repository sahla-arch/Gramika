// splash_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_pg.dart';
import 'customer_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sunController;
  late final AnimationController _particleController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Slow pulsing "breathing" sunrise glow.
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Floating sparkle particles drifting upward.
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final rnd = Random();
    _particles = List.generate(26, (i) => _Particle.random(rnd));

    Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) =>
              user != null ? const CustomerHome() : const LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _sunController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff8B4513),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ---------- BASE SUNSET / SUNRISE GRADIENT ----------
            const _SkyGradient(),

            // ---------- BREATHING SUN GLOW ----------
            AnimatedBuilder(
              animation: _sunController,
              builder: (context, _) {
                final glow = 0.55 + (_sunController.value * 0.25);
                return Align(
                  alignment: const Alignment(0, -0.15),
                  child: Container(
                    width: size.width * 1.1,
                    height: size.width * 1.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xffFFD580).withOpacity(glow * 0.9),
                          const Color(0xffFFA84B).withOpacity(glow * 0.45),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ---------- SOFT DECORATIVE ORBS (glassmorphism) ----------
            Positioned(
              top: -90,
              right: -50,
              child: _GlassOrb(size: 260, opacity: 0.06),
            ),
            Positioned(
              bottom: size.height * 0.32,
              left: -90,
              child: _GlassOrb(size: 300, opacity: 0.045),
            ),

            // ---------- FLOATING PARTICLES ----------
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // ---------- BIRDS (subtle, top right) ----------
            Positioned(
              top: size.height * 0.10,
              right: size.width * 0.08,
              child: CustomPaint(
                size: const Size(110, 50),
                painter: _BirdsPainter(),
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 1200.ms),

            // ---------- KERALA VILLAGE SILHOUETTE (bottom) ----------
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: size.height * 0.40,
                  width: size.width,
                  child: CustomPaint(painter: _VillagePainter()),
                ),
              ),
            ).animate().fadeIn(duration: 1400.ms),

            // ---------- VIGNETTE FOR DEPTH ----------
            const _Vignette(),

            // ---------- MAIN CONTENT ----------
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  // LOGO — glassmorphic card
                  _GramikaLogo()
                      .animate()
                      .scale(
                        duration: 900.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                      )
                      .fadeIn(duration: 700.ms),

                  const SizedBox(height: 30),

                  // TITLE
                  Text(
                        "GRAMIKA",
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(delay: 450.ms, duration: 700.ms)
                      .slideY(
                        begin: .4,
                        end: 0,
                        delay: 450.ms,
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 12),

                  // TAGLINE with decorative lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TaglineLine(),
                      const SizedBox(width: 10),
                      Text(
                        "Your Digital Panchayat",
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TaglineLine(),
                    ],
                  ).animate().fade(delay: 750.ms, duration: 700.ms),

                  const Spacer(flex: 4),

                  // PREMIUM LOADING DOTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(0),
                      const SizedBox(width: 12),
                      _buildDot(180),
                      const SizedBox(width: 12),
                      _buildDot(360),
                    ],
                  ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),

                  const SizedBox(height: 22),

                  Text(
                    "Loading...",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ).animate().fadeIn(delay: 1100.ms, duration: 600.ms),

                  const Spacer(flex: 3),

                  // FOOTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.diversity_3_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Connecting Communities",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1250.ms, duration: 600.ms),

                  const SizedBox(height: 6),

                  Text(
                    "Powered by Gramika",
                    style: GoogleFonts.poppins(
                      color: const Color(0xffFFD9A6).withOpacity(0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
          begin: 0.6,
          end: 1.15,
          delay: Duration(milliseconds: delayMs),
          duration: 500.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(
          begin: 1.15,
          end: 0.6,
          duration: 500.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ============================================================
// LOGO — glassmorphic rounded square with G / home / pin mark
// ============================================================
class _GramikaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // inner soft glow
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
            CustomPaint(
              size: const Size(150, 150),
              painter: _LogoMarkPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a simplified "G + home + location pin + palm" mark,
/// echoing the reference logo, purely with vector paths.
class _LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final white = Paint()..color = Colors.white;
    final accent = Paint()..color = const Color(0xffC86A27);

    // --- Sun behind the mark ---
    final sunPaint = Paint()..color = const Color(0xffFFD27D).withOpacity(0.9);
    canvas.drawCircle(Offset(center.dx + 6, center.dy - 30), 14, sunPaint);

    // sun rays
    final rayPaint = Paint()
      ..color = const Color(0xffFFD27D).withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (pi / 4) * i;
      final start = Offset(
        center.dx + 6 + cos(angle) * 18,
        center.dy - 30 + sin(angle) * 18,
      );
      final end = Offset(
        center.dx + 6 + cos(angle) * 24,
        center.dy - 30 + sin(angle) * 24,
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // --- Location pin shape (the "G" body) ---
    final pinPath = Path();
    final pinCenter = Offset(center.dx, center.dy + 4);
    final r = 30.0;
    pinPath.addOval(Rect.fromCircle(center: pinCenter, radius: r));
    pinPath.moveTo(pinCenter.dx - r * 0.75, pinCenter.dy + r * 0.55);
    pinPath.lineTo(pinCenter.dx, pinCenter.dy + r * 2.05);
    pinPath.lineTo(pinCenter.dx + r * 0.75, pinCenter.dy + r * 0.55);
    pinPath.close();
    canvas.drawPath(pinPath, white);

    // --- House cut-out inside the pin ---
    final housePaint = Paint()..color = const Color(0xffC86A27);
    final houseRect = Rect.fromCenter(
      center: Offset(pinCenter.dx, pinCenter.dy + 4),
      width: 26,
      height: 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(houseRect, const Radius.circular(3)),
      housePaint,
    );

    // roof (triangle)
    final roofPath = Path();
    roofPath.moveTo(houseRect.left - 4, houseRect.top + 2);
    roofPath.lineTo(pinCenter.dx, houseRect.top - 12);
    roofPath.lineTo(houseRect.right + 4, houseRect.top + 2);
    roofPath.close();
    canvas.drawPath(roofPath, housePaint);

    // door
    final doorPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(pinCenter.dx, houseRect.bottom - 5),
        width: 7,
        height: 9,
      ),
      doorPaint,
    );

    // --- Palm tree accent (left) ---
    final palmPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final trunkStart = Offset(center.dx - 42, center.dy + 38);
    final trunkEnd = Offset(center.dx - 38, center.dy - 6);
    canvas.drawLine(trunkStart, trunkEnd, palmPaint);

    final leafPaint = Paint()..color = Colors.white.withOpacity(0.9);
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i - 2) * 0.45;
      final leafEnd = Offset(
        trunkEnd.dx + cos(angle) * 22,
        trunkEnd.dy + sin(angle) * 16,
      );
      final path = Path()
        ..moveTo(trunkEnd.dx, trunkEnd.dy)
        ..quadraticBezierTo(
          trunkEnd.dx + cos(angle) * 12,
          trunkEnd.dy + sin(angle) * 8 - 4,
          leafEnd.dx,
          leafEnd.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawCircle(
      Offset(center.dx - 40, center.dy + 38),
      3,
      Paint()..color = accent.color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// SKY GRADIENT
// ============================================================
class _SkyGradient extends StatelessWidget {
  const _SkyGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xffF4A24A), // warm top sky
            Color(0xffE0792E), // mid sunrise orange
            Color(0xffC4541F), // deeper burnt orange
            Color(0xff4A2410), // near-dark base for village silhouette
          ],
          stops: [0.0, 0.35, 0.62, 1.0],
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class _TaglineLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 1,
      color: Colors.white.withOpacity(0.5),
    );
  }
}

class _GlassOrb extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlassOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================
// PARTICLES (floating sparkles)
// ============================================================
class _Particle {
  double x; // 0..1 horizontal position
  double y; // 0..1 starting vertical position
  double speed; // drift speed multiplier
  double radius;
  double phase; // offset so they don't all twinkle in sync

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.phase,
  });

  factory _Particle.random(Random rnd) {
    return _Particle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      speed: 0.4 + rnd.nextDouble() * 0.8,
      radius: 1.0 + rnd.nextDouble() * 2.2,
      phase: rnd.nextDouble(),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1 looped

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // upward drifting loop
      final t = (progress * p.speed + p.phase) % 1.0;
      final dy = size.height * (1 - t);
      final dx = p.x * size.width + sin((t + p.phase) * 2 * pi) * 10;

      // twinkle opacity
      final twinkle = (sin((t + p.phase) * 2 * pi * 3) + 1) / 2;
      final opacity = (0.15 + twinkle * 0.5).clamp(0.0, 0.65);

      final paint = Paint()
        ..color = const Color(0xffFFE3B0).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ============================================================
// BIRDS (simple V-shaped silhouettes, staggered)
// ============================================================
class _BirdsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final positions = [
      const Offset(10, 10),
      const Offset(32, 0),
      const Offset(56, 14),
      const Offset(80, 4),
      const Offset(98, 18),
    ];
    final scales = [1.0, 0.85, 1.1, 0.75, 0.9];

    for (int i = 0; i < positions.length; i++) {
      _drawBird(canvas, positions[i], scales[i], paint);
    }
  }

  void _drawBird(Canvas canvas, Offset o, double scale, Paint paint) {
    final path = Path()
      ..moveTo(o.dx - 8 * scale, o.dy)
      ..quadraticBezierTo(o.dx - 3 * scale, o.dy - 6 * scale, o.dx, o.dy)
      ..quadraticBezierTo(
        o.dx + 3 * scale,
        o.dy - 6 * scale,
        o.dx + 8 * scale,
        o.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// KERALA VILLAGE SILHOUETTE — palm trees, huts, river, mountains
// ============================================================
class _VillagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final farMountain = Paint()
      ..color = const Color(0xff5C2C12).withOpacity(0.55);
    final nearMountain = Paint()
      ..color = const Color(0xff3E2010).withOpacity(0.7);
    final ground = Paint()..color = const Color(0xff1F0F07);
    final water = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xffE0792E).withOpacity(0.55),
          const Color(0xff1F0F07),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.22, w, h * 0.35));
    final silhouette = Paint()..color = const Color(0xff1A0D06);

    // --- distant mountains ---
    final farPath = Path()
      ..moveTo(0, h * 0.30)
      ..lineTo(w * 0.18, h * 0.18)
      ..lineTo(w * 0.34, h * 0.28)
      ..lineTo(w * 0.55, h * 0.14)
      ..lineTo(w * 0.78, h * 0.27)
      ..lineTo(w, h * 0.17)
      ..lineTo(w, h * 0.40)
      ..lineTo(0, h * 0.40)
      ..close();
    canvas.drawPath(farPath, farMountain);

    final nearPath = Path()
      ..moveTo(0, h * 0.38)
      ..lineTo(w * 0.22, h * 0.27)
      ..lineTo(w * 0.46, h * 0.36)
      ..lineTo(w * 0.70, h * 0.24)
      ..lineTo(w, h * 0.34)
      ..lineTo(w, h * 0.46)
      ..lineTo(0, h * 0.46)
      ..close();
    canvas.drawPath(nearPath, nearMountain);

    // --- river / backwater glow strip ---
    canvas.drawRect(Rect.fromLTWH(0, h * 0.30, w, h * 0.16), water);

    // --- ground / paddy field base ---
    final groundPath = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.5, h * 0.50, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, ground);

    // subtle field furrow lines
    final furrow = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.4;
    for (double i = 0.58; i < 1.0; i += 0.06) {
      canvas.drawLine(Offset(0, h * i), Offset(w, h * (i - 0.02)), furrow);
    }

    // --- huts (left cluster) ---
    _drawHut(canvas, Offset(w * 0.10, h * 0.52), 34, silhouette, lit: true);
    _drawHut(canvas, Offset(w * 0.20, h * 0.55), 28, silhouette, lit: false);

    // --- bigger traditional house (right, like reference) ---
    _drawBigHouse(canvas, Offset(w * 0.84, h * 0.42), silhouette);

    // huts right cluster
    _drawHut(canvas, Offset(w * 0.62, h * 0.56), 26, silhouette, lit: true);
    _drawHut(canvas, Offset(w * 0.70, h * 0.58), 22, silhouette, lit: false);

    // --- palm trees scattered along both edges ---
    final palmSpecs = [
      (Offset(w * 0.04, h * 0.50), 1.1),
      (Offset(w * 0.13, h * 0.40), 0.85),
      (Offset(w * 0.30, h * 0.46), 0.7),
      (Offset(w * 0.92, h * 0.34), 1.2),
      (Offset(w * 0.80, h * 0.30), 0.9),
      (Offset(w * 0.97, h * 0.50), 1.0),
      (Offset(w * 0.46, h * 0.30), 0.6),
    ];
    for (final spec in palmSpecs) {
      _drawPalmTree(canvas, spec.$1, spec.$2, silhouette);
    }

    // foreground grass / reeds
    final grass = Paint()
      ..color = const Color(0xff140A04)
      ..style = PaintingStyle.fill;
    final grassPath = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += w / 14) {
      grassPath.lineTo(x, h - (x % (w / 7) == 0 ? 26 : 14));
    }
    grassPath.lineTo(w, h);
    grassPath.close();
    canvas.drawPath(grassPath, grass);
  }

  void _drawHut(
    Canvas canvas,
    Offset base,
    double scale,
    Paint paint, {
    bool lit = false,
  }) {
    final body = Rect.fromCenter(
      center: Offset(base.dx, base.dy + scale * 0.35),
      width: scale * 1.3,
      height: scale * 0.7,
    );
    canvas.drawRect(body, paint);

    final roof = Path()
      ..moveTo(body.left - scale * 0.2, body.top)
      ..lineTo(base.dx, body.top - scale * 0.55)
      ..lineTo(body.right + scale * 0.2, body.top)
      ..close();
    canvas.drawPath(roof, paint);

    if (lit) {
      final glow = Paint()..color = const Color(0xffFFC97A).withOpacity(0.85);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(base.dx, body.center.dy + 2),
          width: scale * 0.18,
          height: scale * 0.22,
        ),
        glow,
      );
    }
  }

  void _drawBigHouse(Canvas canvas, Offset base, Paint paint) {
    final body = Rect.fromCenter(
      center: Offset(base.dx, base.dy + 30),
      width: 90,
      height: 50,
    );
    canvas.drawRect(body, paint);

    final roof = Path()
      ..moveTo(body.left - 16, body.top)
      ..lineTo(base.dx, body.top - 30)
      ..lineTo(body.right + 16, body.top)
      ..close();
    canvas.drawPath(roof, paint);

    // pillars / verandah hint
    final pillar = Paint()..color = paint.color;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(body.left + 14 + i * 28, body.top, 4, 50),
        pillar,
      );
    }

    // window glow
    final glow = Paint()..color = const Color(0xffFFC97A).withOpacity(0.8);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx - 20, body.top + 30),
        width: 10,
        height: 12,
      ),
      glow,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx + 20, body.top + 30),
        width: 10,
        height: 12,
      ),
      glow,
    );
  }

  void _drawPalmTree(Canvas canvas, Offset base, double scale, Paint paint) {
    final trunkPaint = Paint()
      ..color = paint.color
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;

    final trunkTop = Offset(base.dx + 6 * scale, base.dy - 70 * scale);

    // slightly curved trunk
    final trunkPath = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + 14 * scale,
        base.dy - 40 * scale,
        trunkTop.dx,
        trunkTop.dy,
      );
    canvas.drawPath(
      trunkPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * scale
        ..strokeCap = StrokeCap.round,
    );

    // fronds
    for (int i = 0; i < 6; i++) {
      final angle = -pi / 2 + (i - 2.5) * 0.5;
      final end = Offset(
        trunkTop.dx + cos(angle) * 36 * scale,
        trunkTop.dy + sin(angle) * 24 * scale,
      );
      final frond = Path()
        ..moveTo(trunkTop.dx, trunkTop.dy)
        ..quadraticBezierTo(
          trunkTop.dx + cos(angle) * 18 * scale,
          trunkTop.dy + sin(angle) * 10 * scale - 6 * scale,
          end.dx,
          end.dy,
        );
      canvas.drawPath(
        frond,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
