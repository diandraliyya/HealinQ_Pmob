import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'counselor_chat_list_screen.dart';
import 'counselor_schedule_screen.dart';
import 'counselor_profile_screen.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  State<CounselorDashboardScreen> createState() =>
      _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  int _currentIndex = 0;

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
  final pages = [
  _CounselorDashboardHome(
    onNavigate: _changePage,
  ),
  const CounselorChatListScreen(),
  const CounselorScheduleScreen(),
  const CounselorProfileScreen(),
];

    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CounselorDashboardHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _CounselorDashboardHome({
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final counselor = state.currentCounselor;
    final session = state.currentSession;

    final counselorConsultations = state.consultations.where((item) {
      return item.counselor.id == counselor?.id;
    }).toList();

    final today = DateTime.now();

    final todayConsultations = counselorConsultations.where((item) {
      return item.scheduledAt.year == today.year &&
          item.scheduledAt.month == today.month &&
          item.scheduledAt.day == today.day;
    }).length;

    final upcomingConsultations = counselorConsultations.where((item) {
      return item.scheduledAt.isAfter(DateTime.now());
    }).length;

    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _CounselorSoftBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CounselorTopBar(
                    title: 'Counselor Panel',
                    subtitle: 'Welcome back, ${session?.name ?? 'Counselor'}',
                    onLogout: () {
                      context.read<AppState>().logout();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/onboarding',
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.secondaryLight,
                          child: Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.teal,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counselor?.name ?? 'Counselor',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                counselor?.specialization ??
                                    'General Counseling',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: counselor?.isAvailable == true
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.textLight.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  counselor?.isAvailable == true
                                      ? 'Available'
                                      : 'Not Available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: counselor?.isAvailable == true
                                        ? AppColors.success
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _CounselorStatCard(
                        title: 'Today Session',
                        value: '$todayConsultations',
                        icon: Icons.today_rounded,
                        color: AppColors.primary,
                      ),
                      _CounselorStatCard(
                        title: 'Upcoming',
                        value: '$upcomingConsultations',
                        icon: Icons.event_available_rounded,
                        color: AppColors.teal,
                      ),
                      const _CounselorStatCard(
                        title: 'Unread Chat',
                        value: '3',
                        icon: Icons.mark_chat_unread_rounded,
                        color: AppColors.brandBlue,
                      ),
                      const _CounselorStatCard(
                        title: 'Rating',
                        value: '5.0',
                        icon: Icons.star_rounded,
                        color: AppColors.starYellow,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'Quick Access',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _QuickAccessCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Balas Chat User',
                    subtitle: 'Lihat pesan masuk dan balas konsultasi user.',
                    color: AppColors.brandBlue,
                    onTap: () => onNavigate(1),
                  ),
                  const SizedBox(height: 10),
                  _QuickAccessCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Atur Jadwal Available',
                    subtitle: 'Tentukan hari dan jam konsultasi yang tersedia.',
                    color: AppColors.teal,
                    onTap: () => onNavigate(2),
                  ),
                  const SizedBox(height: 10),
                  _QuickAccessCard(
                    icon: Icons.person_rounded,
                    title: 'Profile Counselor',
                    subtitle: 'Lihat dan kelola informasi akun counselor.',
                    color: AppColors.primary,
                    onTap: () => onNavigate(3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounselorTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onLogout;

  const _CounselorTopBar({
    required this.title,
    required this.subtitle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: onLogout,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.92),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            dateText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _weekday(int value) {
    const map = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return map[value] ?? '';
  }

  String _month(int value) {
    const map = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December',
    };
    return map[value] ?? '';
  }
}

class _CounselorStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CounselorStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounselorComingSoonScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _CounselorComingSoonScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _CounselorSoftBackground(),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        icon,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounselorSoftBackground extends StatelessWidget {
  const _CounselorSoftBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _CounselorBackgroundBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _CounselorBackgroundBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _CounselorBackgroundBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _CounselorBackgroundBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.60,
          heightFactor: 0.22,
          color: AppColors.blobPink,
          opacity: 0.30,
        ),
      ],
    );
  }
}

class _CounselorBackgroundBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _CounselorBackgroundBlob({
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