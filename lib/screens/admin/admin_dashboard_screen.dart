import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_data.dart';
import '../../utils/app_state.dart';
import 'admin_activity_screen.dart';
import 'admin_consultation_screen.dart';
import 'admin_counselors_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _AdminDashboardHome(),
      const AdminUsersScreen(),
      const AdminCounselorsScreen(),
      const AdminConsultationScreen(),
      const AdminActivityScreen(),
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
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11, // kecilin di sini
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            fontSize: 10, // unselected lebih kecil
            fontWeight: FontWeight.w500,
          );
        }),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Counselors',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Consultation',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Activity',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardHome extends StatelessWidget {
  const _AdminDashboardHome();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final session = state.currentSession;

    final int totalUsers = 124;
    final int totalCounselors = AppData.counselors.length;
    final int totalConsultations = AppData.consultationHistories.length;
    final int totalUserContents = AppData.jarItems.length +
        AppData.passionQuestions.length +
        AppData.lyrics.length;

    final List<_AdminStatItem> stats = [
      _AdminStatItem(
        title: 'Total Users',
        value: '$totalUsers',
        icon: Icons.people_rounded,
        color: AppColors.brandBlue,
      ),
      _AdminStatItem(
        title: 'Counselors',
        value: '$totalCounselors',
        icon: Icons.medical_services_rounded,
        color: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Consultations',
        value: '$totalConsultations',
        icon: Icons.calendar_month_rounded,
        color: AppColors.teal,
      ),
      _AdminStatItem(
        title: 'User Content',
        value: '$totalUserContents',
        icon: Icons.auto_stories_rounded,
        color: AppColors.brandGreen,
      ),
    ];

    final recentUsers = const [
      _RecentUserItem(
        name: 'Alya Putri',
        address: 'Jakarta, Indonesia',
        joined: 'Mar 28, 2026',
      ),
      _RecentUserItem(
        name: 'Nadhif Ramadhan',
        address: 'Bandung, Indonesia',
        joined: 'Mar 27, 2026',
      ),
      _RecentUserItem(
        name: 'Citra Maharani',
        address: 'Surabaya, Indonesia',
        joined: 'Mar 26, 2026',
      ),
      _RecentUserItem(
        name: 'Raka Pratama',
        address: 'Yogyakarta, Indonesia',
        joined: 'Mar 25, 2026',
      ),
    ];

    final topCounselors = AppData.counselors.take(4).toList();

    final recentActivities = state.adminActivities.isEmpty
        ? const [
            'Belum ada aktivitas admin terbaru.',
          ]
        : state.adminActivities.reversed.take(5).toList();

    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminSoftBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminTopBar(
                    title: 'Dashboard Overview',
                    subtitle: 'Welcome back, ${session?.name ?? 'Admin'}',
                    onLogout: () {
                      context.read<AppState>().logout();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/onboarding',
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    itemCount: stats.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final item = stats[index];
                      return _AdminStatCard(item: item);
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Recent Users',
                    subtitle: 'New registered users',
                  ),
                  const SizedBox(height: 12),
                  ...recentUsers.map((user) => _RecentUserCard(item: user)),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Top Counselors',
                    subtitle: 'Best visible counselors in the system',
                  ),
                  const SizedBox(height: 12),
                  ...topCounselors.map(
                    (c) => _TopCounselorCard(counselor: c),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Recent Activity',
                    subtitle: 'Latest admin-side activities',
                  ),
                  const SizedBox(height: 12),
                  ...recentActivities.map(
                    (activity) => _ActivityCard(text: activity),
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

class _AdminTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onLogout;

  const _AdminTopBar({
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

class _AdminStatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _AdminStatCard extends StatelessWidget {
  final _AdminStatItem item;

  const _AdminStatCard({required this.item});

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
            backgroundColor: item.color.withOpacity(0.12),
            child: Icon(item.icon, color: item.color),
          ),
          const Spacer(),
          Text(
            item.value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}

class _RecentUserItem {
  final String name;
  final String address;
  final String joined;

  const _RecentUserItem({
    required this.name,
    required this.address,
    required this.joined,
  });
}

class _RecentUserCard extends StatelessWidget {
  final _RecentUserItem item;

  const _RecentUserCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.joined,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCounselorCard extends StatelessWidget {
  final CounselorModel counselor;

  const _TopCounselorCard({required this.counselor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(Icons.medical_services, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counselor.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  counselor.specialization,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${counselor.rating.toStringAsFixed(1)} ★',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String text;

  const _ActivityCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSoftBackground extends StatelessWidget {
  const _AdminSoftBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _AdminBackgroundBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminBackgroundBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminBackgroundBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _AdminBackgroundBlob(
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

class _AdminBackgroundBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminBackgroundBlob({
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
