import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/admin_dashboard_model.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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
    const List<Widget> pages = <Widget>[
      _AdminDashboardHome(),
      AdminUsersScreen(),
      AdminCounselorsScreen(),
      AdminConsultationScreen(),
      AdminActivityScreen(),
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
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            return TextStyle(
              fontSize: states.contains(
                WidgetState.selected,
              )
                  ? 11
                  : 10,
              fontWeight: states.contains(
                WidgetState.selected,
              )
                  ? FontWeight.w600
                  : FontWeight.w500,
            );
          },
        ),
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.people_rounded,
            ),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.medical_services_outlined,
            ),
            selectedIcon: Icon(
              Icons.medical_services_rounded,
            ),
            label: 'Counselors',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon: Icon(
              Icons.receipt_long_rounded,
            ),
            label: 'Consultation',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
            ),
            selectedIcon: Icon(
              Icons.history_rounded,
            ),
            label: 'Activity',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardHome extends StatefulWidget {
  const _AdminDashboardHome();

  @override
  State<_AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<_AdminDashboardHome> {
  final AdminDashboardService _service = AdminDashboardService();

  final AuthService _authService = AuthService();

  AdminDashboardModel? _dashboard;

  bool _isLoading = true;
  bool _isLoggingOut = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final AdminDashboardModel result = await _service.getOverview();

      if (!mounted) return;

      setState(() {
        _dashboard = result;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AdminSoftBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () {
                return _loadDashboard(
                  showLoading: false,
                );
              },
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 260),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null || _dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 100),
          _DashboardError(
            message: _errorMessage ?? 'Dashboard tidak dapat dimuat.',
            onRetry: _loadDashboard,
          ),
        ],
      );
    }

    final AdminDashboardModel data = _dashboard!;

    final List<_AdminStatItem> stats = <_AdminStatItem>[
      _AdminStatItem(
        title: 'Total Users',
        value: '${data.totalUsers}',
        icon: Icons.people_rounded,
        color: AppColors.brandBlue,
      ),
      _AdminStatItem(
        title: 'Counselors',
        value: '${data.totalCounselors}',
        icon: Icons.medical_services_rounded,
        color: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Consultations',
        value: '${data.totalConsultations}',
        icon: Icons.calendar_month_rounded,
        color: AppColors.teal,
      ),
      _AdminStatItem(
        title: 'Total Content',
        value: '${data.totalContent}',
        icon: Icons.auto_stories_rounded,
        color: AppColors.brandGreen,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        28,
      ),
      children: <Widget>[
        _AdminTopBar(
          adminName: data.adminName,
          isLoggingOut: _isLoggingOut,
          onRefresh: _loadDashboard,
          onLogout: _logout,
        ),
        const SizedBox(height: 18),
        GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            return _AdminStatCard(
              item: stats[index],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniInfoCard(
                title: 'Pending Counselors',
                value: '${data.pendingCounselors}',
                icon: Icons.person_search_rounded,
                color: const Color(0xFFD68A1F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniInfoCard(
                title: 'Payment Verification',
                value: '${data.pendingPayments}',
                icon: Icons.payments_outlined,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Recent Users',
          subtitle: 'User terbaru yang terdaftar',
        ),
        const SizedBox(height: 12),
        if (data.recentUsers.isEmpty)
          const _EmptyDashboardCard(
            message: 'Belum ada user terdaftar.',
          )
        else
          ...data.recentUsers.map(
            (
              AdminDashboardUserModel user,
            ) {
              return _RecentUserCard(
                item: user,
              );
            },
          ),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Top Counselors',
          subtitle: 'Counselor aktif berdasarkan rating',
        ),
        const SizedBox(height: 12),
        if (data.topCounselors.isEmpty)
          const _EmptyDashboardCard(
            message: 'Belum ada counselor aktif dan approved.',
          )
        else
          ...data.topCounselors.map(
            (
              AdminDashboardCounselorModel counselor,
            ) {
              return _TopCounselorCard(
                counselor: counselor,
              );
            },
          ),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Recent Activity',
          subtitle: 'Lima aktivitas sistem terbaru',
        ),
        const SizedBox(height: 12),
        if (data.recentActivities.isEmpty)
          const _EmptyDashboardCard(
            message: 'Belum ada activity log.',
          )
        else
          ...data.recentActivities.map(
            (
              AdminDashboardActivityModel activity,
            ) {
              return _ActivityCard(
                activity: activity,
              );
            },
          ),
      ],
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String adminName;
  final bool isLoggingOut;

  final Future<void> Function({
    bool showLoading,
  }) onRefresh;

  final Future<void> Function() onLogout;

  const _AdminTopBar({
    required this.adminName,
    required this.isLoggingOut,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Dashboard Overview',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                onRefresh(
                  showLoading: true,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.92),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Logout',
              onPressed: isLoggingOut ? null : onLogout,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.92),
              ),
              icon: isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
            ),
          ],
        ),
        Text(
          'Welcome back, $adminName',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: Text(
            DateFormat(
              'EEEE, d MMMM yyyy',
            ).format(now),
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

  const _AdminStatCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: item.color.withOpacity(0.12),
            child: Icon(
              item.icon,
              color: item.color,
            ),
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
          Text(
            item.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
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
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}

class _RecentUserCard extends StatelessWidget {
  final AdminDashboardUserModel item;

  const _RecentUserCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              item.fullName.trim().isEmpty
                  ? 'U'
                  : item.fullName.trim()[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  item.address?.trim().isNotEmpty == true
                      ? item.address!
                      : '@${item.username}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'd MMM yyyy',
            ).format(
              item.createdAt,
            ),
            style: GoogleFonts.poppins(
              fontSize: 9,
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
  final AdminDashboardCounselorModel counselor;

  const _TopCounselorCard({
    required this.counselor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(
              Icons.medical_services,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  counselor.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  counselor.specialization,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Text(
              '${counselor.rating.toStringAsFixed(1)} ★ '
              '(${counselor.ratingCount})',
              style: GoogleFonts.poppins(
                fontSize: 9,
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
  final AdminDashboardActivityModel activity;

  const _ActivityCard({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(
              top: 5,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.action,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${activity.actorName} • '
                  '${activity.category}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(
                    activity.createdAt,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final String message;

  const _EmptyDashboardCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.textMedium,
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  final Future<void> Function({
    bool showLoading,
  }) onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              onRetry(
                showLoading: true,
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Try Again'),
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
      children: <Widget>[
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
    final Size size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size.width * widthFactor,
          height: size.height * heightFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withOpacity(
                  opacity,
                ),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
