import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import 'auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _welcomeBaseColor = Color(0xFFD4EFFC);
  static const Color _welcomeTitleColor = Color(0xFF4AA7A2);
  static const Color _welcomeSubtitleColor = Color(0xFF4AA7A2);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildAboutPage(),
              _buildWelcomePage(),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 2,
                  effect: const WormEffect(
                    dotColor: Colors.white54,
                    activeDotColor: AppColors.primary,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                const SizedBox(height: 20),
                if (_currentPage == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Geser ke kiri untuk lanjut →',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F7FA), Color(0xFFFCE4EC)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildLogoIcon(size: 80),
                  const SizedBox(height: 8),
                  Text(
                    'HealinQ',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                'About Us',
                'HealinQ adalah platform digital pendamping kesehatan mental yang menyediakan layanan edukasi, konsultasi dengan psikolog, serta berbagai self-care tools interaktif. Dirancang untuk membantu pengguna mengenali, memahami, dan mengelola kondisi emosional secara mandiri maupun dengan dukungan profesional.',
                isAbout: true,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                'Konsultasi',
                'assets/icons/ic_konsultasi.png',
                AppColors.primary,
                'Fitur Konsultasi menyediakan layanan pendampingan bersama psikolog atau konselor profesional secara online. Pengguna dapat memilih jadwal sesi, menyampaikan keluhan secara privat, serta mendapatkan arahan yang sesuai dengan kondisi mereka.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                'Self-Healing',
                'assets/icons/ic_self_healing.png',
                AppColors.teal,
                'Fitur Self-Healing Tools berupa journaling membantu pengguna mengekspresikan pikiran dan perasaan secara tertulis. Tersedia panduan pertanyaan reflektif, pelacak suasana hati (mood tracker), serta latihan afirmasi positif.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                'FYP',
                'assets/icons/ic_fyp.png',
                AppColors.accent,
                'Fitur FYP (Find Your Passion) membantu pengguna mengenali minat, potensi, dan tujuan hidup melalui tes minat, kuis refleksi diri, serta rekomendasi aktivitas yang sesuai dengan kepribadian mereka.',
              ),
              const SizedBox(height: 24),
              _buildVisiMisiCard(),
              const SizedBox(height: 16),
              _buildDisclaimerCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, {bool isAbout = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAbout) ...[
            Row(
              children: [
                _buildLogoIcon(size: 50),
                const SizedBox(width: 12),
                Text(
                  'HealinQ',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D5F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          if (!isAbout) const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String iconPath,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'See More',
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisiMisiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Visi & Misi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Menjadi platform pendamping kesehatan mental terdepan yang menciptakan ekosistem digital aman dan suportif bagi setiap individu untuk tumbuh, memahami diri, dan meraih kesejahteraan emosional.',
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Memberikan Pertolongan Pertama Kesehatan Mental',
            'Meningkatkan Literasi Kesehatan Mental',
            'Mempermudah Akses Konsultasi Profesional',
            'Menciptakan Ruang Aman dan Suportif',
            'Mendukung Proses Pengembangan Diri'
          ].asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Disclaimer!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jika Anda mengalami krisis emosional berat atau memiliki pikiran untuk menyakiti diri sendiri atau orang lain, segera hubungi psikolog/psikiater atau layanan darurat kesehatan mental yang telah tersedia.',
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Scaffold(
      backgroundColor: _welcomeBaseColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Column(
                        children: [
                          const SizedBox(height: 68),
                          Text(
                            'Welcome!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: _welcomeTitleColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Take your time. We’re here for you.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _welcomeSubtitleColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 92),
                          _buildLogoIcon(size: 210),
                          const SizedBox(height: 125),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WelcomeScreen(goToLogin: true),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF4AA7A2),
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WelcomeScreen(goToLogin: false),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF4AA7A2),
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                'Create a new account',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoIcon({double size = 60}) {
    return Image.asset(
      'assets/images/logo_healinq.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(width: size, height: size);
      },
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _WelcomeGradientBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.75,
          heightFactor: 0.26,
          color: Color(0xFFFFE5F4),
          opacity: 0.95,
        ),
        _WelcomeGradientBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.8,
          heightFactor: 0.3,
          color: Color(0xFF53BAB3),
          opacity: 0.36,
        ),
        _WelcomeGradientBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.0,
          heightFactor: 0.58,
          color: Color(0xFF9BDAF8),
          opacity: 0.30,
        ),
        _WelcomeGradientBlob(
          alignment: Alignment.bottomLeft,
          widthFactor: 0.85,
          heightFactor: 0.28,
          color: Color(0xFF53BAB3),
          opacity: 0.18,
        ),
        _WelcomeGradientBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.65,
          heightFactor: 0.22,
          color: Color(0xFFFFE5F4),
          opacity: 0.34,
        ),
      ],
    );
  }
}

class _WelcomeGradientBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _WelcomeGradientBlob({
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