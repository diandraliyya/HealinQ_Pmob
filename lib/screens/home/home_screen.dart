import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../utils/app_data.dart';
import '../../widgets/common_widgets.dart';
import '../konsultasi/konsultasi_screen.dart';
import '../self_healing/self_healing_screen.dart';
import '../fyp/fyp_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<Widget> _screens = const [
    _HomeContent(),
    KonsultasiScreen(),
    _ProfileTab(),
    SelfHealingScreen(),
    FypScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_navIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static const Color _baseColor = Color(0xFFD4EFFC);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Container(
      color: _baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _SoftPageBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 200),
                      ScoreCard(xp: user?.point ?? 0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                Text(
                                  ' ${user?.streak ?? 0}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const _MascotImage(size: 32),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Buddy!',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '$dateStr. How\'s your day?',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGreetingCard(),
                        const SizedBox(height: 20),
                        Text(
                          'QUICK ACCESS',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAccess(context),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Journal',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  Text(
                                    ' New',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...state.journals.take(3).map(
                              (j) => _buildJournalItem(
                                j.moodTag ?? '😐',
                                j.title,
                                j.createdAt,
                              ),
                            ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Consultation History',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'See All',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildConsultationHistory(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Counselor',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'View All',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...AppData.counselors.take(3).map(
                              (c) => CounselorCard(
                                name: c.name,
                                specialization: c.specialization,
                                rating: c.rating,
                                onBook: () {},
                              ),
                            ),
                        const SizedBox(height: 20),
                        _buildLyricCard(),
                        const SizedBox(height: 20),
                        _buildScoreProgress(
                          user?.point ?? 0,
                          user?.level ?? 1,
                          user?.streak ?? 0,
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Aku Alin, temanmu di HealinQ. Yuk kenali perasaanmu, pahami dirimu lebih dalam, dan tumbuh pelan-pelan bersama.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: _MascotImage(size: 92),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      children: [
        _quickCard(
          'assets/icons/ic_self_healing.png',
          'Self Healing',
          'Write your feelings and reflect on your day',
          AppColors.secondaryLight,
        ),
        const SizedBox(height: 12),
        _quickCard(
          'assets/icons/ic_konsultasi.png',
          'Konsultasi',
          'We will help you here',
          AppColors.secondaryLight,
        ),
        const SizedBox(height: 12),
        _quickCard(
          'assets/icons/ic_fyp.png',
          'Find Your Passion',
          'Let\'s find your own passion',
          AppColors.secondaryLight,
        ),
        const SizedBox(height: 12),
        _buildJarCard(),
      ],
    );
  }

  Widget _quickCard(
    String iconPath,
    String title,
    String subtitle,
    Color bg,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 24, height: 24);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 12, 114, 166),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/jar.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 56, height: 56);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jar of Happiness',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click here!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalItem(String emoji, String title, DateTime date) {
    final dateStr = DateFormat('d MMM').format(date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:  const Color.fromARGB(255, 198, 241, 237),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                dateStr,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationHistory() {
    final dates = [16, 15, 14, 13, 12, 11, 10, 9];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          itemBuilder: (ctx, row) => Row(
            children: dates
                .skip(row * 4)
                .take(4)
                .map(
                  (d) => Container(
                    width: 60,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.pinkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Center(
                      child: Text(
                        '$d\nMarch',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricCard() {
    final lyric = AppData.lyricOfTheDay;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              Text(
                ' Lyric Of The Day',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lyric['title'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lyric['lyric'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreProgress(int xp, int level, int streak) {
    const nextLevelXp = 1500;
    final progress = (xp % nextLevelXp) / nextLevelXp;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Score Progress',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _scoreRow('Streak', '$streak days', AppColors.primary),
          const SizedBox(height: 10),
          _scoreRow('XP', '$xp', AppColors.accent),
          const SizedBox(height: 10),
          _scoreRow('Level', '$level', AppColors.teal),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Next level in ${nextLevelXp - (xp % nextLevelXp)} XP',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  static const Color _baseColor = Color(0xFFD4EFFC);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Container(
      color: _baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _SoftPageBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '@${user?.username ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCard('Level', '${user?.level ?? 1}', AppColors.teal),
                      _statCard('XP', '${user?.point ?? 0}', AppColors.primary),
                      _statCard(
                        'Streak',
                        '${user?.streak ?? 0} 🔥',
                        AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _profileMenuItem(Icons.edit_rounded, 'Edit Profile', () {}),
                  _profileMenuItem(
                    Icons.history_rounded,
                    'Consultation History',
                    () {},
                  ),
                  _profileMenuItem(Icons.book_rounded, 'My Journals', () {}),
                  _profileMenuItem(Icons.settings_rounded, 'Settings', () {}),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppState>().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const _LogoutRedirect(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textLight,
      ),
      onTap: onTap,
    );
  }
}

class _LogoutRedirect extends StatelessWidget {
  const _LogoutRedirect();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _OnboardingRedirect()),
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OnboardingRedirect extends StatelessWidget {
  const _OnboardingRedirect();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _OnboardingPage()),
        (route) => false,
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage();

  @override
  Widget build(BuildContext context) {
    return const _SplashRedirect();
  }
}

class _SplashRedirect extends StatelessWidget {
  const _SplashRedirect();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MascotImage extends StatelessWidget {
  final double size;

  const _MascotImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/maskot1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(width: size, height: size);
      },
    );
  }
}

class _SoftPageBackground extends StatelessWidget {
  const _SoftPageBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _BackgroundBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.76,
          heightFactor: 0.25,
          color: Color(0xFFFFE5F4),
          opacity: 0.95,
        ),
        _BackgroundBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: Color(0xFF53BAB3),
          opacity: 0.34,
        ),
        _BackgroundBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: Color(0xFF9BDAF8),
          opacity: 0.28,
        ),
        _BackgroundBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.60,
          heightFactor: 0.22,
          color: Color(0xFFFFE5F4),
          opacity: 0.30,
        ),
      ],
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _BackgroundBlob({
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
      child: IgnorePointer(
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
      ),
    );
  }
}
