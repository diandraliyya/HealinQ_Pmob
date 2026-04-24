import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../chat/room_chat_screen.dart';
import 'my_bookings_screen.dart';

class BookingTicketScreen extends StatefulWidget {
  final ConsultationModel consultation;
  final bool isOffline;
  final bool fromMyBookings;

  const BookingTicketScreen({
    super.key,
    required this.consultation,
    required this.isOffline,
    this.fromMyBookings = false,
  });

  @override
  State<BookingTicketScreen> createState() => _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen> {
  late bool _isConfirmed;
  late Duration _timeRemaining;
  Timer? _timer;

  bool get _isOffline => widget.isOffline;
  bool get _isOnline => !widget.isOffline;

  DateTime get _sessionStart => widget.consultation.scheduledAt;

  DateTime get _sessionEnd => widget.consultation.scheduledAt.add(
        const Duration(hours: 1),
      );

  bool get _isBeforeSession {
    final now = DateTime.now();
    return now.isBefore(_sessionStart);
  }

  bool get _isDuringSession {
    final now = DateTime.now();

    return (now.isAtSameMomentAs(_sessionStart) || now.isAfter(_sessionStart)) &&
        now.isBefore(_sessionEnd);
  }

  bool get _isSessionEnded {
    final now = DateTime.now();
    return now.isAtSameMomentAs(_sessionEnd) || now.isAfter(_sessionEnd);
  }

  bool get _canConfirmBooking {
    if (_isOffline) return true;

    return _isOnline && _isDuringSession;
  }

  bool get _canOpenRoomChat {
    return _isOnline && _isConfirmed && _isDuringSession;
  }

  @override
  void initState() {
    super.initState();

    _isConfirmed = widget.consultation.status == 'Confirmed';

    _timeRemaining = _sessionStart.difference(DateTime.now());
    if (_timeRemaining.isNegative) {
      _timeRemaining = Duration.zero;
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _sessionStart.difference(DateTime.now());

      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });

      if (_timeRemaining == Duration.zero && _isSessionEnded) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00:00';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  ConsultationModel _currentConsultation() {
    return widget.consultation.copyWith(
      status: _isConfirmed ? 'Confirmed' : widget.consultation.status,
    );
  }

  void _confirmBooking() {
    if (!_canConfirmBooking) {
      _showCannotConfirmMessage();
      return;
    }

    setState(() {
      _isConfirmed = true;
    });

    context.read<AppState>().updateConsultationStatus(
          widget.consultation.id,
          'Confirmed',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking confirmed successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showCannotConfirmMessage() {
    String message;

    if (_isOnline && _isBeforeSession) {
      message =
          'Belum bisa konfirmasi. Tunggu sampai jadwal konsultasi online dimulai.';
    } else if (_isOnline && _isSessionEnded) {
      message =
          'Jadwal konsultasi online sudah lewat. Booking ini tidak bisa dikonfirmasi lagi.';
    } else {
      message = 'Booking belum bisa dikonfirmasi.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openRoomChat() {
    if (!_canOpenRoomChat) {
      String message;

      if (!_isConfirmed) {
        message = 'Konsultasi online belum dikonfirmasi.';
      } else if (_isBeforeSession) {
        message = 'Room chat hanya bisa dibuka saat jadwal konsultasi dimulai.';
      } else if (_isSessionEnded) {
        message =
            'Sesi konsultasi sudah selesai. Room chat tidak bisa dibuka lagi.';
      } else {
        message = 'Room chat belum bisa dibuka.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoomChatScreen(
          counselor: widget.consultation.counselor,
          consultation: _currentConsultation(),
        ),
      ),
    );
  }

  void _goToMyBookings() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MyBookingsScreen(),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultation = _currentConsultation();

    final dateText = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(consultation.scheduledAt);

    final timeText =
        '${DateFormat('HH.00').format(_sessionStart)}-${DateFormat('HH.00').format(_sessionEnd)} WIB';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB2EBF2), Color(0xFFFCE4EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Booking Ticket',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const ScoreCard(xp: 1240),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTicket(
                        consultation,
                        dateText,
                        timeText,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _buildStatusText(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildMainTimeText(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: _isConfirmed ? 24 : 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBottomAction(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildStatusText() {
    if (_isConfirmed) {
      if (_isOffline) {
        return 'Your offline ticket has been confirmed';
      }

      if (_isSessionEnded) {
        return 'Your online consultation session has ended';
      }

      if (_isBeforeSession) {
        return 'Your online booking has been confirmed. Room chat will open when the session starts.';
      }

      return 'Your online booking has been confirmed';
    }

    if (_isOnline && _isBeforeSession) {
      return 'Online consultation can be confirmed when the schedule starts in:';
    }

    if (_isOnline && _isSessionEnded) {
      return 'This online consultation schedule has passed';
    }

    return 'Your session is ready to be confirmed';
  }

  String _buildMainTimeText() {
    if (_isConfirmed) {
      if (_isOffline) {
        return 'Show this ticket at location';
      }

      if (_isSessionEnded) {
        return 'Session Ended';
      }

      if (_isBeforeSession) {
        return _formatDuration(_timeRemaining);
      }

      return 'Ready to Start';
    }

    if (_isOnline && _isSessionEnded) {
      return 'Expired';
    }

    return _formatDuration(_timeRemaining);
  }

  Widget _buildBottomAction() {
    if (!_isConfirmed) {
      return Column(
        children: [
          _ActionButton(
            text: _getConfirmButtonText(),
            icon: _getConfirmButtonIcon(),
            color: _canConfirmBooking
                ? AppColors.primaryLight
                : AppColors.textLight.withOpacity(0.18),
            textColor:
                _canConfirmBooking ? AppColors.primary : AppColors.textMedium,
            borderColor:
                _canConfirmBooking ? AppColors.primary : AppColors.textLight,
            onTap: _canConfirmBooking ? _confirmBooking : _showCannotConfirmMessage,
          ),
          if (_isOnline && _isBeforeSession) ...[
            const SizedBox(height: 10),
            Text(
              'Tombol konfirmasi akan aktif saat tanggal dan jam konsultasi online sudah sesuai.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
          if (_isOnline && _isSessionEnded) ...[
            const SizedBox(height: 10),
            Text(
              'Jadwal konsultasi online sudah lewat. Silakan buat booking baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.error,
                height: 1.5,
              ),
            ),
          ],
        ],
      );
    }

    if (_isOnline) {
      if (_isSessionEnded) {
        return Column(
          children: [
            _ActionButton(
              text: 'Session Ended',
              icon: Icons.event_busy_rounded,
              color: AppColors.textLight.withOpacity(0.18),
              textColor: AppColors.textMedium,
              borderColor: AppColors.textLight,
              onTap: _openRoomChat,
            ),
            const SizedBox(height: 10),
            Text(
              'Sesi konsultasi online sudah selesai. Room chat tidak bisa dibuka lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
        );
      }

      if (_isBeforeSession) {
        return Column(
          children: [
            _ActionButton(
              text: 'Room Chat Belum Aktif',
              icon: Icons.lock_clock_rounded,
              color: AppColors.textLight.withOpacity(0.18),
              textColor: AppColors.textMedium,
              borderColor: AppColors.textLight,
              onTap: _openRoomChat,
            ),
            const SizedBox(height: 10),
            Text(
              'Room chat akan aktif saat jadwal konsultasi dimulai.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
        );
      }

      return _ActionButton(
        text: 'Go to Room Chat',
        icon: Icons.chat_bubble_rounded,
        color: AppColors.primary,
        textColor: AppColors.white,
        borderColor: AppColors.primary,
        onTap: _openRoomChat,
      );
    }

    return Column(
      children: [
        _ActionButton(
          text: 'Back to My Bookings',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
          textColor: AppColors.white,
          borderColor: AppColors.primary,
          onTap: _goToMyBookings,
        ),
        const SizedBox(height: 10),
        Text(
          'Untuk konsultasi offline, kamu tidak perlu masuk room chat. Simpan atau buka ulang tiket ini dari My Bookings.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _getConfirmButtonText() {
    if (_isOnline && _isBeforeSession) {
      return 'Belum Bisa Konfirmasi';
    }

    if (_isOnline && _isSessionEnded) {
      return 'Jadwal Sudah Lewat';
    }

    return 'Konfirmasi Booking';
  }

  IconData _getConfirmButtonIcon() {
    if (_isOnline && _isBeforeSession) {
      return Icons.lock_clock_rounded;
    }

    if (_isOnline && _isSessionEnded) {
      return Icons.event_busy_rounded;
    }

    return Icons.check_circle_rounded;
  }

  Widget _buildTicket(
    ConsultationModel consultation,
    String dateText,
    String timeText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              _isConfirmed ? 'Booking Confirmed!' : 'Booking Summary',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.secondaryLight,
                      child: Icon(
                        Icons.person,
                        color: AppColors.teal,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.counselor.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${consultation.counselor.specialization} | ${consultation.type}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 14,
                                ),
                                Text(
                                  ' Verified',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFFFB6C1)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        Icons.calendar_today_rounded,
                        'Tanggal',
                        dateText,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoBox(
                        Icons.access_time_rounded,
                        'Time Session',
                        timeText,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _fullInfoBox(
                  Icons.confirmation_number_rounded,
                  'Booking Code',
                  consultation.bookingCode,
                ),
                const SizedBox(height: 8),
                if (_isOffline)
                  _fullInfoBox(
                    Icons.location_on_rounded,
                    'Location',
                    consultation.counselor.location,
                  ),
                if (_isOffline) const SizedBox(height: 8),
                _fullInfoBox(
                  Icons.chat_bubble_outline_rounded,
                  'Consultation Preview',
                  consultation.notes?.isNotEmpty == true
                      ? consultation.notes!
                      : '-',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB2EBF2),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _DashedLinePainter(),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoBox(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullInfoBox(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..strokeWidth = 1.5;

    double x = 0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + 6, size.height / 2),
        paint,
      );
      x += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}