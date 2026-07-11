import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/booking_model.dart';
import '../../models/content_models.dart';
import '../../models/models.dart';
import '../../models/user_counselor_model.dart';
import '../../services/booking_service.dart';
import '../../services/content_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_consultation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../fyp/fyp_screen.dart';
import '../konsultasi/booking_ticket_screen.dart';
import '../konsultasi/konsultasi_screen.dart';
import '../konsultasi/my_bookings_screen.dart';
import '../self_healing/self_healing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookingService _bookingService = BookingService();
  final UserConsultationService _consultationService =
      UserConsultationService();

  int _navIndex = 0;

  List<BookingModel> _homeBookings = <BookingModel>[];
  List<UserCounselorModel> _homeCounselors =
      <UserCounselorModel>[];

  bool _isLoadingBookings = true;
  bool _isLoadingCounselors = true;

  String? _bookingError;
  String? _counselorError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHomeData(showLoading: true);
    });
  }

  Future<void> _refreshHomeData({
    bool showLoading = false,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _loadBookings(showLoading: showLoading),
      _loadCounselors(showLoading: showLoading),
      _refreshProfileQuietly(),
      _refreshJournalsQuietly(),
    ]);
  }

  Future<void> _loadBookings({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoadingBookings = true;
        _bookingError = null;
      });
    }

    try {
      final List<BookingModel> result =
          await _bookingService.getMyBookings();

      result.sort(
        (BookingModel first, BookingModel second) =>
            second.scheduledStart.compareTo(
          first.scheduledStart,
        ),
      );

      if (!mounted) return;

      setState(() {
        _homeBookings = result;
        _bookingError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _bookingError = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  Future<void> _loadCounselors({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoadingCounselors = true;
        _counselorError = null;
      });
    }

    try {
      final List<UserCounselorModel> online =
          await _consultationService.getCounselors(
        offline: false,
      );

      final List<UserCounselorModel> offline =
          await _consultationService.getCounselors(
        offline: true,
      );

      final Map<String, UserCounselorModel> merged =
          <String, UserCounselorModel>{};

      for (final UserCounselorModel counselor
          in <UserCounselorModel>[...online, ...offline]) {
        merged[counselor.id] = counselor;
      }

      final List<UserCounselorModel> result =
          merged.values.toList()
            ..sort(
              (
                UserCounselorModel first,
                UserCounselorModel second,
              ) {
                final int ratingComparison =
                    second.rating.compareTo(
                  first.rating,
                );

                if (ratingComparison != 0) {
                  return ratingComparison;
                }

                return second.totalReviews.compareTo(
                  first.totalReviews,
                );
              },
            );

      if (!mounted) return;

      setState(() {
        _homeCounselors = result;
        _counselorError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _counselorError = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCounselors = false;
        });
      }
    }
  }

  Future<void> _refreshProfileQuietly() async {
    try {
      final User? authUser =
          Supabase.instance.client.auth.currentUser;

      if (authUser == null) return;

      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(
        await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', authUser.id)
            .single(),
      );

      if (!mounted) return;

      context.read<AppState>().setUserFromProfile(
            profile,
          );
    } catch (_) {
      // Home tetap dapat ditampilkan memakai profil yang sudah ada.
    }
  }

  Future<void> _refreshJournalsQuietly() async {
    try {
      await context.read<AppState>().loadJournals(
            force: true,
          );
    } catch (_) {
      // Error jurnal ditampilkan oleh state jurnal pada section terkait.
    }
  }

  Future<void> _openBookingDetail(
    BookingModel booking,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BookingTicketScreen(
          consultationId: booking.consultationId,
        ),
      ),
    );

    if (mounted) {
      await _loadBookings(showLoading: false);
    }
  }

  Future<void> _openMyBookings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MyBookingsScreen(),
      ),
    );

    if (mounted) {
      await _loadBookings(showLoading: false);
    }
  }

  void _changeTab(int index) {
    setState(() {
      _navIndex = index;
    });

    if (index == 0) {
      _refreshHomeData(showLoading: false);
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: <Widget>[
          _HomeContent(
            bookings: _homeBookings,
            counselors: _homeCounselors,
            isLoadingBookings: _isLoadingBookings,
            isLoadingCounselors: _isLoadingCounselors,
            bookingError: _bookingError,
            counselorError: _counselorError,
            onNavigateToTab: _changeTab,
            onRefresh: () {
              return _refreshHomeData(
                showLoading: false,
              );
            },
            onRetryBookings: () {
              return _loadBookings(
                showLoading: true,
              );
            },
            onRetryCounselors: () {
              return _loadCounselors(
                showLoading: true,
              );
            },
            onOpenBooking: _openBookingDetail,
            onOpenMyBookings: _openMyBookings,
          ),
          const KonsultasiScreen(),
          const _ProfileTab(),
          const SelfHealingScreen(),
          const FypScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _changeTab,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<BookingModel> bookings;
  final List<UserCounselorModel> counselors;
  final bool isLoadingBookings;
  final bool isLoadingCounselors;
  final String? bookingError;
  final String? counselorError;
  final ValueChanged<int> onNavigateToTab;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryBookings;
  final Future<void> Function() onRetryCounselors;
  final Future<void> Function(
    BookingModel booking,
  ) onOpenBooking;
  final Future<void> Function() onOpenMyBookings;

  const _HomeContent({
    required this.bookings,
    required this.counselors,
    required this.isLoadingBookings,
    required this.isLoadingCounselors,
    required this.bookingError,
    required this.counselorError,
    required this.onNavigateToTab,
    required this.onRefresh,
    required this.onRetryBookings,
    required this.onRetryCounselors,
    required this.onOpenBooking,
    required this.onOpenMyBookings,
  });

  static const Color _baseColor =
      AppColors.bgGradientStart;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final UserModel? user = state.currentUser;
    final DateTime now = DateTime.now();
    final String dateStr = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(now);

    return Container(
      color: _baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _SoftPageBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: onRefresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28,
                ),
                children: <Widget>[
                  _buildTopBar(),
                  const SizedBox(height: 12),
                  Text(
                    'Hello, ${user?.name ?? 'Buddy'}!',
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
                  _buildQuickAccess(),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Recent Journal',
                    actionLabel: 'View All',
                    onAction: () {
                      onNavigateToTab(3);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildRecentJournals(
                    context,
                    state,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Consultation History',
                    actionLabel: 'View All',
                    onAction: onOpenMyBookings,
                  ),
                  const SizedBox(height: 10),
                  _buildConsultationHistory(),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Counselor',
                    actionLabel: 'Go to Consultation',
                    onAction: () {
                      onNavigateToTab(1);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCounselorSection(),
                  const SizedBox(height: 20),
                  const _DailyLyricCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'HealinQ',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const _MascotImage(size: 36),
      ],
    );
  }

  Widget _buildRecentJournals(
    BuildContext context,
    AppState state,
  ) {
    if (state.isLoadingJournals &&
        state.journals.isEmpty) {
      return const _HomeLoadingCard();
    }

    if (state.journalError != null &&
        state.journals.isEmpty) {
      return _HomeErrorCard(
        message: state.journalError!,
        onRetry: () async {
          try {
            await context
                .read<AppState>()
                .loadJournals(force: true);
          } catch (_) {
            // Error tetap ditampilkan melalui journalError.
          }
        },
      );
    }

    if (state.journals.isEmpty) {
      return _HomeEmptyCard(
        icon: Icons.menu_book_rounded,
        title: 'Belum ada jurnal',
        description:
            'Tap untuk mulai menulis dan menyimpan ceritamu.',
        onTap: () {
          onNavigateToTab(3);
        },
      );
    }

    return Column(
      children: state.journals
          .take(3)
          .map(
            (JournalModel journal) =>
                _buildJournalItem(
              journal.moodTag ?? '😐',
              journal.title.isEmpty
                  ? 'Untitled Note'
                  : journal.title,
              journal.createdAt,
            ),
          )
          .toList(),
    );
  }

  Widget _buildConsultationHistory() {
    if (isLoadingBookings && bookings.isEmpty) {
      return const _HomeLoadingCard();
    }

    if (bookingError != null && bookings.isEmpty) {
      return _HomeErrorCard(
        message: bookingError!,
        onRetry: onRetryBookings,
      );
    }

    if (bookings.isEmpty) {
      return _HomeEmptyCard(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada konsultasi',
        description:
            'Booking konsultasi pertamamu akan tampil di sini.',
        onTap: () {
          onNavigateToTab(1);
        },
      );
    }

    final List<BookingModel> visible =
        bookings.take(5).toList();

    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final BookingModel booking =
              visible[index];

          return _HomeBookingCard(
            booking: booking,
            onTap: () {
              onOpenBooking(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildCounselorSection() {
    if (isLoadingCounselors &&
        counselors.isEmpty) {
      return const _HomeLoadingCard();
    }

    if (counselorError != null &&
        counselors.isEmpty) {
      return _HomeErrorCard(
        message: counselorError!,
        onRetry: onRetryCounselors,
      );
    }

    if (counselors.isEmpty) {
      return _HomeEmptyCard(
        icon: Icons.psychology_alt_rounded,
        title: 'Belum ada counselor tersedia',
        description:
            'Counselor dengan jadwal aktif akan tampil di sini.',
        onTap: () {
          onNavigateToTab(1);
        },
      );
    }

    return Column(
      children: counselors
          .take(3)
          .map(
            (UserCounselorModel counselor) =>
                _HomeCounselorCard(
              counselor: counselor,
              onTap: () {
                onNavigateToTab(1);
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
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

  Widget _buildQuickAccess() {
    return GestureDetector(
      onTap: () {
        onNavigateToTab(3);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pinkCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Image.asset(
              'assets/images/jar.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const SizedBox(
                  width: 56,
                  height: 56,
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalItem(
    String emoji,
    String title,
    DateTime date,
  ) {
    final String dateStr =
        DateFormat('d MMM').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mintCard,
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _HomeBookingCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        _statusColor(booking.consultationStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 202,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: booking.isOnline
                        ? AppColors.secondaryLight
                        : AppColors.primarySoft,
                    child: Icon(
                      booking.isOnline
                          ? Icons.videocam_rounded
                          : Icons.location_on_rounded,
                      color: booking.isOnline
                          ? AppColors.teal
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      booking.counselorName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                DateFormat('d MMM yyyy • HH:mm').format(
                  booking.scheduledStart,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.bookingCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.consultationStatusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return const Color(0xFFD68A1F);
      case 'waiting_verification':
        return AppColors.brandBlue;
      case 'confirmed':
      case 'ongoing':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

class _HomeCounselorCard extends StatelessWidget {
  final UserCounselorModel counselor;
  final VoidCallback onTap;

  const _HomeCounselorCard({
    required this.counselor,
    required this.onTap,
  });

  static String _buildAvatarUrl(
    String? avatarPath,
  ) {
    final String path =
        avatarPath?.trim() ?? '';

    if (path.isEmpty) {
      return '';
    }

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    return Supabase.instance.client.storage
        .from('profile-pictures')
        .getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final String avatarUrl =
        _buildAvatarUrl(
      counselor.avatarPath,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 27,
                  backgroundColor:
                      AppColors.secondaryLight,
                  backgroundImage:
                      avatarUrl.trim().isEmpty
                          ? null
                          : NetworkImage(avatarUrl),
                  child: avatarUrl.trim().isEmpty
                      ? const Icon(
                          Icons
                              .medical_services_rounded,
                          color: AppColors.teal,
                          size: 27,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        counselor.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        counselor.specialization,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:
                              AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star_rounded,
                            color:
                                AppColors.starYellow,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${counselor.rating.toStringAsFixed(1)} '
                            '(${counselor.totalReviews})',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  AppColors.textDark,
                            ),
                          ),
                          if (counselor
                              .location.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 13,
                              color:
                                  AppColors.textLight,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                counselor.location,
                                maxLines: 1,
                                overflow: TextOverflow
                                    .ellipsis,
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: AppColors
                                      .textMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingCard extends StatelessWidget {
  const _HomeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _HomeErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _HomeErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeEmptyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppColors.primarySoft,
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color:
                            AppColors.textMedium,
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

class _DailyLyricCard extends StatefulWidget {
  const _DailyLyricCard();

  @override
  State<_DailyLyricCard> createState() => _DailyLyricCardState();
}

class _DailyLyricCardState extends State<_DailyLyricCard> {
  final ContentService _service = ContentService();

  LyricContentModel? _lyric;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLyric();
  }

  Future<void> _loadLyric() async {
    try {
      final LyricContentModel? result = await _service.getLyricOfTheDay();

      if (!mounted) return;

      setState(() {
        _lyric = result;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          : _errorMessage != null
              ? Column(
                  children: <Widget>[
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadLyric,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text('Refresh'),
                    ),
                  ],
                )
              : _lyric == null
                  ? Text(
                      'Belum ada Lyric of the Day aktif.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
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
                          _lyric!.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          _lyric!.artist,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lyric!.lyricExcerpt,
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
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final paint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..strokeWidth = 1.5;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  static const Color _baseColor = AppColors.bgGradientStart;

  Future<void> _pickProfileImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return;
    }

    try {
      final ProfileService service = ProfileService();

      final bytes = await image.readAsBytes();

      await service.uploadAvatar(
        bytes: bytes,
        fileName: image.name,
        mimeType: image.mimeType,
      );

      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (!mounted) {
        return;
      }

      context.read<AppState>().setUserFromProfile(profile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto profile berhasil diperbarui',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal upload foto: $error',
          ),
        ),
      );
    }
  }

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: user?.avatarPath != null &&
                                        user!.avatarPath!.isNotEmpty
                                    ? NetworkImage(
                                        ProfileService().getAvatarUrl(
                                          user.avatarPath,
                                        ),
                                      )
                                    : null,
                                child: user?.avatarPath == null ||
                                        user!.avatarPath!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 58,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    _pickProfileImage(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.name ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user?.username ?? 'username'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? 'user@email.com',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Joined since 2026',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Account',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _profileMenuCard(
                    context,
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Change your name, username, and email',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _profileMenuCard(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () async {
                      final bool? changed =
                          await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              const _ChangePasswordScreen(),
                        ),
                      );

                      if (!context.mounted || changed != true) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password berhasil diperbarui.',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: 10),
                  _profileMenuCard(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About App',
                    subtitle: 'Learn more about HealinQ',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _AboutAppScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AppState>().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const _LogoutRedirect(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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

  Widget _profileMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
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

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AppState>().updateProfile(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SoftPageBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 58,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildFieldLabel('Full Name'),
                      const SizedBox(height: 8),
                      _profileTextField(
                        controller: _nameController,
                        hintText: 'Enter your full name',
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Username'),
                      const SizedBox(height: 8),
                      _profileTextField(
                        controller: _usernameController,
                        hintText: 'Enter your username',
                        icon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Email'),
                      const SizedBox(height: 8),
                      _profileTextField(
                        controller: _emailController,
                        hintText: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email cannot be empty';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _profileTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textLight,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        filled: true,
        fillColor: const Color(0xFFF3DDE7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.1,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<_ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final TextEditingController
      _currentPasswordController =
      TextEditingController();
  final TextEditingController
      _newPasswordController =
      TextEditingController();
  final TextEditingController
      _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    final bool valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.changePassword(
        currentPassword:
            _currentPasswordController.text,
        newPassword:
            _newPasswordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (!mounted) return;

      _showErrorMessage(
        _translateAuthError(error.message),
      );
    } catch (error) {
      if (!mounted) return;

      _showErrorMessage(
        _cleanErrorMessage(error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _translateAuthError(String message) {
    final String lowerMessage =
        message.toLowerCase();

    if (lowerMessage.contains(
          'invalid login credentials',
        ) ||
        lowerMessage.contains(
          'invalid credentials',
        )) {
      return 'Password saat ini salah.';
    }

    if (lowerMessage.contains(
          'different from the old password',
        ) ||
        lowerMessage.contains(
          'same password',
        )) {
      return 'Password baru harus berbeda dari password lama.';
    }

    if (lowerMessage.contains('weak password') ||
        lowerMessage.contains(
          'password should be at least',
        )) {
      return 'Password baru belum memenuhi ketentuan keamanan.';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('socket') ||
        lowerMessage.contains('connection')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }

    return message;
  }

  String _cleanErrorMessage(String message) {
    return message
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.bgGradientStart,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent,
        foregroundColor:
            AppColors.primary,
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontWeight:
                FontWeight.w600,
            color:
                AppColors.primary,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _SoftPageBackground(),
          SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                24,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color: AppColors.white
                      .withOpacity(0.92),
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors
                                .primaryLight,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 42,
                          color:
                              AppColors.primary,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _passwordField(
                        controller:
                            _currentPasswordController,
                        label:
                            'Current Password',
                        obscureText:
                            _obscureCurrent,
                        enabled:
                            !_isLoading,
                        onToggle: () {
                          setState(() {
                            _obscureCurrent =
                                !_obscureCurrent;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Current password cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _passwordField(
                        controller:
                            _newPasswordController,
                        label:
                            'New Password',
                        obscureText:
                            _obscureNew,
                        enabled:
                            !_isLoading,
                        onToggle: () {
                          setState(() {
                            _obscureNew =
                                !_obscureNew;
                          });
                        },
                        validator: (value) {
                          final String password =
                              value ?? '';

                          if (password.isEmpty) {
                            return 'New password cannot be empty';
                          }

                          if (password.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          if (password ==
                              _currentPasswordController
                                  .text) {
                            return 'New password must be different';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _passwordField(
                        controller:
                            _confirmPasswordController,
                        label:
                            'Confirm New Password',
                        obscureText:
                            _obscureConfirm,
                        enabled:
                            !_isLoading,
                        onToggle: () {
                          setState(() {
                            _obscureConfirm =
                                !_obscureConfirm;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please confirm your new password';
                          }

                          if (value !=
                              _newPasswordController
                                  .text) {
                            return 'Confirmation password does not match';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _handleChangePassword,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors
                                    .primary,
                            foregroundColor:
                                AppColors.white,
                            disabledBackgroundColor:
                                AppColors
                                    .primary
                                    .withOpacity(
                                      0.55,
                                    ),
                            disabledForegroundColor:
                                AppColors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 15,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.2,
                                    color:
                                        AppColors
                                            .white,
                                  ),
                                )
                              : Text(
                                  'Save New Password',
                                  style:
                                      GoogleFonts
                                          .poppins(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required bool enabled,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      enableSuggestions: false,
      autocorrect: false,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textMedium,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          onPressed:
              enabled ? onToggle : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_off
                : Icons.visibility,
            color: AppColors.textMedium,
          ),
        ),
        filled: true,
        fillColor:
            AppColors.primarySoft,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle:
            GoogleFonts.poppins(
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AboutAppScreen extends StatelessWidget {
  const _AboutAppScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        title: Text(
          'About App',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SoftPageBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo_healinq.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary,
                            size: 36,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HealinQ is a mental health companion app designed to help users understand their feelings, write journals, and access consultations in a simple and friendly way.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Developed for',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pemrograman Mobile Project',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _BackgroundBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _BackgroundBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _BackgroundBlob(
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
