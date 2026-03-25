import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  static const Color _baseColor = Color(0xFFD4EFFC);
  static const Color _titleColor = Color(0xFF4AA7A2);
  static const Color _subtitleColor = Color(0xFF4AA7A2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: _baseColor,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SplashBackground(),
            Positioned.fill(
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        const Spacer(flex: 7),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              Text(
                                'Welcome to HealinQ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: _titleColor,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A safe space to grow, heal, and understand yourself',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: _subtitleColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/splash_bottom.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _GradientBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.72,
          heightFactor: 0.28,
          color: Color(0xFFFFE5F4),
          opacity: 0.95,
        ),
        _GradientBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.78,
          heightFactor: 0.34,
          color: Color(0xFF53BAB3),
          opacity: 0.38,
        ),
        _GradientBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 0.92,
          heightFactor: 0.62,
          color: Color(0xFF9BDAF8),
          opacity: 0.36,
        ),
        _GradientBlob(
          alignment: Alignment.bottomLeft,
          widthFactor: 1.05,
          heightFactor: 0.34,
          color: Color(0xFF53BAB3),
          opacity: 0.22,
        ),
        _GradientBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.55,
          heightFactor: 0.2,
          color: Color(0xFFFFE5F4),
          opacity: 0.4,
        ),
      ],
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _GradientBlob({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: Container(
        width: size.width * widthFactor,
        height: size.height * heightFactor,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
