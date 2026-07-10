import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import 'counselor_chat_list_screen.dart';
import 'counselor_profile_screen.dart';
import 'counselor_schedule_screen.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  State<CounselorDashboardScreen> createState() =>
      _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState
    extends State<CounselorDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _currentIndex = 0;

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  _CounselorDashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _changePage(int index) async {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      await _loadDashboard(showLoading: false);
    }
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
      final User? authUser = _supabase.auth.currentUser;

      if (authUser == null) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(
        await _supabase
            .from('profiles')
            .select(
              'id, username, full_name, email, role, status, avatar_path',
            )
            .eq('id', authUser.id)
            .single(),
      );

      if (profile['role']?.toString() != 'counselor') {
        throw Exception(
          'Dashboard ini hanya dapat diakses oleh counselor.',
        );
      }

      final Map<String, dynamic> counselorProfile =
          Map<String, dynamic>.from(
        await _supabase
            .from('counselor_profiles')
            .select(
              'specialization, rating, rating_count, is_available',
            )
            .eq('id', authUser.id)
            .single(),
      );

      final List<dynamic> rawConsultations = await _supabase
          .from('consultations')
          .select(
            'id, booking_code, user_id, consultation_type, '
            'scheduled_start, scheduled_end, status, attendance_status',
          )
          .eq('counselor_id', authUser.id)
          .order('scheduled_start', ascending: true);

      final List<dynamic> rawSlots = await _supabase
          .from('counselor_slots')
          .select(
            'id, consultation_type, status, start_at, end_at',
          )
          .eq('counselor_id', authUser.id)
          .order('start_at', ascending: true);

      final List<dynamic> rawRooms = await _supabase
          .from('chat_rooms')
          .select('id')
          .eq('counselor_id', authUser.id);

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      );
      final DateTime tomorrowStart = todayStart.add(
        const Duration(days: 1),
      );

      int todaySessions = 0;
      int upcomingSessions = 0;
      int availableSlots = 0;
      int unreadMessages = 0;

      final List<_DashboardConsultation> consultations =
          <_DashboardConsultation>[];

      for (final dynamic raw in rawConsultations) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(raw as Map);

        final String status = item['status']?.toString() ?? '';
        final DateTime startAt = DateTime.parse(
          item['scheduled_start'].toString(),
        ).toLocal();
        final DateTime endAt = DateTime.parse(
          item['scheduled_end'].toString(),
        ).toLocal();

        final bool isValidSession = <String>{
          'confirmed',
          'ongoing',
          'completed',
        }.contains(status);

        final bool isToday = !startAt.isBefore(todayStart) &&
            startAt.isBefore(tomorrowStart);

        if (isValidSession && isToday) {
          todaySessions++;
        }

        if (status == 'confirmed' && startAt.isAfter(now)) {
          upcomingSessions++;
        }

        final String userId = item['user_id']?.toString() ?? '';

        consultations.add(
          _DashboardConsultation(
            id: item['id']?.toString() ?? '',
            bookingCode: item['booking_code']?.toString() ?? '-',
            userId: userId,
            userName: 'User',
            consultationType:
                item['consultation_type']?.toString() ?? 'online',
            scheduledStart: startAt,
            scheduledEnd: endAt,
            status: status,
            attendanceStatus:
                item['attendance_status']?.toString() ?? '',
          ),
        );
      }

      for (final dynamic raw in rawSlots) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(raw as Map);

        final String status = item['status']?.toString() ?? '';
        final DateTime endAt = DateTime.parse(
          item['end_at'].toString(),
        ).toLocal();

        if (status == 'available' && endAt.isAfter(now)) {
          availableSlots++;
        }
      }

      if (rawRooms.isNotEmpty) {
        final List<String> roomIds = rawRooms
            .map(
              (dynamic raw) => Map<String, dynamic>.from(
                raw as Map,
              )['id']?.toString() ?? '',
            )
            .where((String id) => id.isNotEmpty)
            .toList();

        if (roomIds.isNotEmpty) {
          final List<dynamic> unreadRows = await _supabase
              .from('messages')
              .select('id')
              .inFilter('room_id', roomIds)
              .neq('sender_id', authUser.id)
              .isFilter('read_at', null);

          unreadMessages = unreadRows.length;
        }
      }

      final Map<String, String> userNameById =
          <String, String>{};

      final List<String> consultationIds =
          consultations
              .map(
                (_DashboardConsultation item) =>
                    item.id,
              )
              .where(
                (String id) => id.isNotEmpty,
              )
              .toList();

      if (consultationIds.isNotEmpty) {
        final List<dynamic> rawUsers =
            await _supabase.rpc(
          'get_my_consultation_clients',
          params: <String, dynamic>{
            'p_consultation_ids':
                consultationIds,
          },
        );

        for (final dynamic raw in rawUsers) {
          final Map<String, dynamic> item =
              Map<String, dynamic>.from(
            raw as Map,
          );

          final String id =
              item['user_id']?.toString() ??
                  '';

          final String name =
              item['full_name']
                      ?.toString()
                      .trim() ??
                  '';

          if (id.isNotEmpty) {
            userNameById[id] = name.isEmpty
                ? 'User'
                : name;
          }
        }
      }

      final List<_DashboardConsultation> namedConsultations =
          consultations
              .map(
                (_DashboardConsultation item) => item.copyWith(
                  userName: userNameById[item.userId] ?? 'User',
                ),
              )
              .toList();

      _DashboardConsultation? nextSession;

      for (final _DashboardConsultation item
          in namedConsultations) {
        final bool canBecomeNext = <String>{
              'confirmed',
              'ongoing',
            }.contains(item.status) &&
            item.scheduledEnd.isAfter(now);

        if (!canBecomeNext) {
          continue;
        }

        if (nextSession == null ||
            item.scheduledStart.isBefore(
              nextSession.scheduledStart,
            )) {
          nextSession = item;
        }
      }

      final String? avatarPath =
          profile['avatar_path']?.toString().trim();

      final String? avatarUrl =
          avatarPath == null || avatarPath.isEmpty
              ? null
              : _supabase.storage
                  .from('profile-pictures')
                  .getPublicUrl(avatarPath);

      final _CounselorDashboardData result =
          _CounselorDashboardData(
        fullName:
            profile['full_name']?.toString().trim().isNotEmpty == true
                ? profile['full_name'].toString().trim()
                : 'Counselor',
        email: profile['email']?.toString() ?? authUser.email ?? '-',
        username: profile['username']?.toString() ?? '',
        accountStatus: profile['status']?.toString() ?? '',
        specialization:
            counselorProfile['specialization']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? counselorProfile['specialization']
                    .toString()
                    .trim()
                : 'General Counseling',
        rating: _toDouble(counselorProfile['rating']),
        ratingCount: _toInt(
          counselorProfile['rating_count'],
        ),
        isAvailable:
            counselorProfile['is_available'] == true ||
            availableSlots > 0,
        todaySessions: todaySessions,
        upcomingSessions: upcomingSessions,
        availableSlots: availableSlots,
        unreadMessages: unreadMessages,
        avatarUrl: avatarUrl,
        nextSession: nextSession,
      );

      if (!mounted) return;

      setState(() {
        _dashboardData = result;
        _errorMessage = null;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _translatePostgrestError(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(
          error.toString(),
        );
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
      await _supabase.auth.signOut();

      if (!mounted) return;

      context.read<AppState>().logout();

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanErrorMessage(error.toString()),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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

  String _translatePostgrestError(
    PostgrestException error,
  ) {
    final String message =
        '${error.code ?? ''} ${error.message} '
        '${error.details ?? ''}'.toLowerCase();

    if (message.contains('row-level security') ||
        message.contains('42501') ||
        message.contains('permission denied')) {
      return 'Kamu tidak memiliki izin untuk membaca data dashboard.';
    }

    if (message.contains('multiple') &&
        message.contains('rows')) {
      return 'Data counselor tidak valid atau duplikat.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal memuat dashboard counselor.'
        : error.message.trim();
  }

  String _cleanErrorMessage(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _CounselorDashboardHome(
        data: _dashboardData,
        isLoading: _isLoading,
        isLoggingOut: _isLoggingOut,
        errorMessage: _errorMessage,
        onRefresh: () {
          return _loadDashboard(
            showLoading: false,
          );
        },
        onRetry: _loadDashboard,
        onNavigate: _changePage,
        onLogout: _logout,
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
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (int index) {
          _changePage(index);
        },
        destinations: const <NavigationDestination>[
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
  final _CounselorDashboardData? data;
  final bool isLoading;
  final bool isLoggingOut;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function({
    bool showLoading,
  }) onRetry;
  final Future<void> Function(int index) onNavigate;
  final Future<void> Function() onLogout;

  const _CounselorDashboardHome({
    required this.data,
    required this.isLoading,
    required this.isLoggingOut,
    required this.errorMessage,
    required this.onRefresh,
    required this.onRetry,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _CounselorSoftBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: onRefresh,
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && data == null) {
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

    if (errorMessage != null && data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 100),
          _DashboardErrorCard(
            message: errorMessage!,
            onRetry: () {
              onRetry(showLoading: true);
            },
          ),
        ],
      );
    }

    final _CounselorDashboardData currentData =
        data ??
            const _CounselorDashboardData(
              fullName: 'Counselor',
              email: '-',
              username: '',
              accountStatus: '',
              specialization: 'General Counseling',
              rating: 0,
              ratingCount: 0,
              isAvailable: false,
              todaySessions: 0,
              upcomingSessions: 0,
              availableSlots: 0,
              unreadMessages: 0,
            );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        26,
      ),
      children: <Widget>[
        _CounselorTopBar(
          title: 'Counselor Panel',
          subtitle: 'Welcome back, ${currentData.fullName}',
          isLoggingOut: isLoggingOut,
          onLogout: onLogout,
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildProfileCard(currentData),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _CounselorStatCard(
              title: 'Today Sessions',
              value: '${currentData.todaySessions}',
              icon: Icons.today_rounded,
              color: AppColors.primary,
            ),
            _CounselorStatCard(
              title: 'Upcoming',
              value: '${currentData.upcomingSessions}',
              icon: Icons.event_available_rounded,
              color: AppColors.teal,
            ),
            _CounselorStatCard(
              title: 'Available Slots',
              value: '${currentData.availableSlots}',
              icon: Icons.schedule_rounded,
              color: AppColors.brandBlue,
            ),
            _CounselorStatCard(
              title: 'Unread Chats',
              value: '${currentData.unreadMessages}',
              icon: Icons.mark_chat_unread_rounded,
              color: AppColors.starYellow,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Next Consultation',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _NextSessionCard(
          consultation: currentData.nextSession,
          onOpenSchedule: () {
            onNavigate(2);
          },
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
          subtitle: currentData.unreadMessages > 0
              ? '${currentData.unreadMessages} pesan belum dibaca.'
              : 'Lihat dan balas konsultasi online user.',
          color: AppColors.brandBlue,
          onTap: () {
            onNavigate(1);
          },
        ),
        const SizedBox(height: 10),
        _QuickAccessCard(
          icon: Icons.calendar_month_rounded,
          title: 'Atur Jadwal Konsultasi',
          subtitle:
              'Tambah, lihat, atau nonaktifkan slot konsultasi.',
          color: AppColors.teal,
          onTap: () {
            onNavigate(2);
          },
        ),
        const SizedBox(height: 10),
        _QuickAccessCard(
          icon: Icons.person_rounded,
          title: 'Profile Counselor',
          subtitle:
              'Lihat dan kelola informasi akun counselor.',
          color: AppColors.primary,
          onTap: () {
            onNavigate(3);
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    _CounselorDashboardData data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _CounselorAvatar(
            avatarUrl: data.avatarUrl,
            radius: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    _DashboardBadge(
                      label: data.isAvailable
                          ? 'Available'
                          : 'Not Available',
                      color: data.isAvailable
                          ? AppColors.success
                          : AppColors.textMedium,
                    ),
                    _DashboardBadge(
                      label: _formatStatus(data.accountStatus),
                      color: _statusColor(
                        data.accountStatus,
                      ),
                    ),
                    _DashboardBadge(
                      label:
                          '★ ${data.rating.toStringAsFixed(1)} (${data.ratingCount})',
                      color: AppColors.starYellow,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';

    return status[0].toUpperCase() + status.substring(1);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return const Color(0xFFD68A1F);
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }
}

class _NextSessionCard extends StatelessWidget {
  final _DashboardConsultation? consultation;
  final VoidCallback onOpenSchedule;

  const _NextSessionCard({
    required this.consultation,
    required this.onOpenSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final _DashboardConsultation? item = consultation;

    if (item == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.event_busy_rounded,
              size: 42,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada konsultasi berikutnya',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Booking yang sudah dikonfirmasi akan tampil di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    final bool isOnline = item.consultationType == 'online';
    final bool isOngoing = item.status == 'ongoing';

    return InkWell(
      onTap: onOpenSchedule,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: isOnline
                  ? AppColors.primarySoft
                  : AppColors.secondaryLight,
              child: Icon(
                isOnline
                    ? Icons.chat_bubble_rounded
                    : Icons.location_on_rounded,
                color: isOnline
                    ? AppColors.primary
                    : AppColors.teal,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isOngoing
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOngoing ? 'ONGOING' : 'CONFIRMED',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isOngoing
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isOnline ? 'Online' : 'Offline'} • ${item.bookingCode}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${DateFormat('EEE, d MMM yyyy').format(item.scheduledStart)} • '
                          '${DateFormat('HH:mm').format(item.scheduledStart)}–'
                          '${DateFormat('HH:mm').format(item.scheduledEnd)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _CounselorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const _CounselorAvatar({
    required this.avatarUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.secondaryLight,
        child: Icon(
          Icons.medical_services_rounded,
          color: AppColors.teal,
          size: radius,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondaryLight,
      child: ClipOval(
        child: Image.network(
          avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Icon(
              Icons.medical_services_rounded,
              color: AppColors.teal,
              size: radius,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DashboardBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CounselorTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLoggingOut;
  final Future<void> Function() onLogout;

  const _CounselorTopBar({
    required this.title,
    required this.subtitle,
    required this.isLoggingOut,
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
                title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: isLoggingOut ? null : onLogout,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.92),
              ),
              icon: isLoggingOut
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
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
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            DateFormat('EEEE, d MMMM yyyy').format(now),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
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
                  children: <Widget>[
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

class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(26),
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
            'Failed to load dashboard',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _CounselorDashboardData {
  final String fullName;
  final String email;
  final String username;
  final String accountStatus;
  final String specialization;
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final int todaySessions;
  final int upcomingSessions;
  final int availableSlots;
  final int unreadMessages;
  final String? avatarUrl;
  final _DashboardConsultation? nextSession;

  const _CounselorDashboardData({
    required this.fullName,
    required this.email,
    required this.username,
    required this.accountStatus,
    required this.specialization,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    required this.todaySessions,
    required this.upcomingSessions,
    required this.availableSlots,
    required this.unreadMessages,
    this.avatarUrl,
    this.nextSession,
  });
}

class _DashboardConsultation {
  final String id;
  final String bookingCode;
  final String userId;
  final String userName;
  final String consultationType;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String status;
  final String attendanceStatus;

  const _DashboardConsultation({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.userName,
    required this.consultationType,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.attendanceStatus,
  });

  _DashboardConsultation copyWith({
    String? userName,
  }) {
    return _DashboardConsultation(
      id: id,
      bookingCode: bookingCode,
      userId: userId,
      userName: userName ?? this.userName,
      consultationType: consultationType,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: status,
      attendanceStatus: attendanceStatus,
    );
  }
}

class _CounselorSoftBackground extends StatelessWidget {
  const _CounselorSoftBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
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
