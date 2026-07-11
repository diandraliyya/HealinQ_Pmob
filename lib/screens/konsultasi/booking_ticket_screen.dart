import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/counselor_review_dialog.dart';
import '../chat/room_chat_screen.dart';
import 'payment_screen.dart';

class BookingTicketScreen extends StatefulWidget {
  final String consultationId;

  const BookingTicketScreen({
    super.key,
    required this.consultationId,
  });

  @override
  State<BookingTicketScreen> createState() =>
      _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen> {
  final BookingService _service = BookingService();

  BookingModel? _booking;
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;
  Timer? _attendanceTimer;

  @override
  void initState() {
    super.initState();
    _loadBooking();

    /*
     * Memperbarui kondisi tombol jika halaman dibiarkan terbuka
     * ketika memasuki H-1 atau ketika jadwal dimulai.
     */
    _attendanceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _attendanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooking({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final BookingModel booking =
          await _service.getBookingById(widget.consultationId);

      if (!mounted) return;

      setState(() {
        _booking = booking;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAttendance() async {
    final BookingModel? booking = _booking;
    if (booking == null || _isMutating) return;

    setState(() {
      _isMutating = true;
    });

    try {
      await _service.confirmOfflineAttendance(booking.consultationId);
      await _loadBooking(showLoading: false);
      if (!mounted) return;
      _showMessage('Kehadiran offline berhasil dikonfirmasi.', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final BookingModel? booking = _booking;

    if (booking == null ||
        _isMutating ||
        !booking.canCancelBooking) {
      return;
    }

    final String? reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelBookingDialog(),
    );

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await _service.cancelBooking(
        consultationId:
            booking.consultationId,
        reason: reason,
      );

      await _loadBooking(
        showLoading: false,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Booking berhasil dibatalkan dan slot tersedia kembali.',
        isError: false,
      );
    } catch (error) {
      if (mounted) {
        await _loadBooking(
          showLoading: false,
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _openChat(BookingModel booking) async {
    final String? roomId = booking.chatRoomId;

    if (roomId == null || roomId.isEmpty) {
      _showMessage(
        'Room chat belum tersedia. Silakan refresh halaman.',
        isError: true,
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomChatScreen(roomId: roomId),
      ),
    );

    if (mounted) {
      await _loadBooking(showLoading: false);
    }
  }

  Future<void> _openReviewDialog(
    BookingModel booking,
  ) async {
    final bool? submitted =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CounselorReviewDialog(
        booking: booking,
      ),
    );

    if (submitted != true || !mounted) {
      return;
    }

    await _loadBooking(
      showLoading: false,
    );

    if (!mounted) return;

    _showMessage(
      'Terima kasih! Rating counselor berhasil dikirim.',
      isError: false,
    );
  }

  Future<void> _continuePayment() async {
    final BookingModel? booking = _booking;
    if (booking == null || booking.paymentId.isEmpty) return;

    final bool? submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PaymentScreen(
          consultationId: booking.consultationId,
          paymentId: booking.paymentId,
          amount: booking.amount,
        ),
      ),
    );

    if (submitted == true && mounted) {
      await _loadBooking(showLoading: false);
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFB2EBF2),
              Color(0xFFFCE4EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _loadBooking(showLoading: false),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              'Booking Detail',
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadBooking,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
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
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 90),
          _buildErrorState(),
        ],
      );
    }

    final BookingModel booking = _booking!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: <Widget>[
        _buildStatusCard(booking),
        const SizedBox(height: 14),
        _buildTicketCard(booking),
        const SizedBox(height: 14),
        _buildPaymentCard(booking),
        if (booking.isOffline) ...<Widget>[
          const SizedBox(height: 14),
          _buildAttendanceCard(booking),
        ],
        if (booking.paymentStatus == 'rejected') ...<Widget>[
          const SizedBox(height: 12),
          _buildRejectedCard(booking),
        ],
        if ((booking.consultationStatus == 'cancelled' ||
                booking.consultationStatus == 'expired') &&
            booking.cancellationReason?.trim().isNotEmpty == true) ...<Widget>[
          const SizedBox(height: 12),
          _buildCancellationCard(booking),
        ],
        const SizedBox(height: 18),
        _buildAction(booking),
        if (booking.canReviewCounselor ||
            booking.hasReview) ...<Widget>[
          const SizedBox(height: 14),
          _buildReviewCard(booking),
        ],
      ],
    );
  }

  Widget _buildStatusCard(BookingModel booking) {
    final Color color = _statusColor(booking.consultationStatus);
    final String description;

    switch (booking.consultationStatus) {
      case 'pending_payment':
        description = booking.paymentStatus == 'rejected'
            ? 'Bukti pembayaran ditolak. Unggah ulang sebelum '
                '${_formatPaymentDeadline(booking)} WIB.'
            : 'Selesaikan pembayaran sebelum '
                '${_formatPaymentDeadline(booking)} WIB. '
                'Setelah itu booking otomatis kedaluwarsa.';
        break;
      case 'waiting_verification':
        description =
            'Bukti pembayaran sudah terkirim dan sedang diperiksa admin.';
        break;
      case 'confirmed':
        description =
            'Pembayaran telah disetujui. Jadwal konsultasi sudah final.';
        break;
      case 'ongoing':
        description = 'Sesi konsultasi sedang berlangsung.';
        break;
      case 'completed':
        description = 'Sesi konsultasi telah selesai.';
        break;
      case 'cancelled':
        description = 'Booking konsultasi dibatalkan.';
        break;
      case 'expired':
        description = 'Booking konsultasi telah kedaluwarsa.';
        break;
      default:
        description = 'Status booking sedang diproses.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              _statusIcon(booking.consultationStatus),
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  booking.consultationStatusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.55,
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

  Widget _buildTicketCard(BookingModel booking) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Text(
              booking.bookingCode,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                _detailRow('Counselor', booking.counselorName),
                _detailRow('Specialization', booking.specialization),
                _detailRow(
                  'Type',
                  booking.consultationType.toUpperCase(),
                ),
                _detailRow(
                  'Schedule',
                  DateFormat('EEEE, d MMM yyyy • HH:mm').format(
                    booking.scheduledStart,
                  ),
                ),
                _detailRow(
                  'Duration',
                  '${booking.scheduledEnd.difference(booking.scheduledStart).inMinutes} minutes',
                ),
                if (booking.isOffline)
                  _detailRow('Location', booking.location),
                _detailRow(
                  'Notes',
                  booking.notes?.trim().isNotEmpty == true
                      ? booking.notes!.trim()
                      : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Payment Information',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 13),
          _detailRow('Amount', _formatCurrency(booking.amount)),
          _detailRow('Payment Status', booking.paymentStatusLabel),
          _detailRow(
            'Submitted At',
            booking.submittedAt == null
                ? '-'
                : DateFormat('d MMM yyyy, HH:mm').format(
                    booking.submittedAt!,
                  ),
          ),
          _detailRow(
            'Verified At',
            booking.verifiedAt == null
                ? '-'
                : DateFormat('d MMM yyyy, HH:mm').format(
                    booking.verifiedAt!,
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildAttendanceCard(BookingModel booking) {
    final Color color;
    if (booking.attendanceStatus == 'attended') {
      color = AppColors.success;
    } else if (booking.attendanceStatus == 'absent') {
      color = AppColors.error;
    } else if (booking.isAttendanceConfirmed) {
      color = AppColors.success;
    } else if (booking.isAttendanceWindowOpen && booking.consultationStatus == 'confirmed' && booking.paymentStatus == 'paid') {
      color = AppColors.primary;
    } else {
      color = const Color(0xFFD68A1F);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                booking.attendanceStatus == 'attended'
                    ? Icons.how_to_reg_rounded
                    : booking.attendanceStatus == 'absent'
                        ? Icons.person_off_rounded
                        : Icons.event_available_rounded,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Offline Attendance',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _detailRow('User Confirmation', booking.userConfirmationLabel),
          _detailRow('Actual Attendance', booking.actualAttendanceLabel),
          if (booking.attendanceMarkedAt != null)
            _detailRow(
              'Recorded At',
              DateFormat('d MMM yyyy, HH:mm').format(booking.attendanceMarkedAt!),
            ),
          if (!booking.isActualAttendanceFinal)
            _detailRow('Confirmation Opens', '${_formatAttendanceOpenAt(booking)} WIB'),
          const SizedBox(height: 2),
          Text(
            _attendanceInformation(booking),
            style: GoogleFonts.poppins(fontSize: 10, height: 1.55, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Alasan penolakan: '
              '${booking.rejectionReason?.trim().isNotEmpty == true ? booking.rejectionReason : 'Bukti pembayaran tidak valid.'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.55,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCancellationCard(BookingModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              booking.cancellationReason!.trim(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.55,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BookingModel booking,
  ) {
    if (booking.hasReview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.starYellow
              .withOpacity(0.10),
          borderRadius:
              BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Review',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Row(
                  children:
                      List<Widget>.generate(
                    5,
                    (int index) => Icon(
                      index <
                              (booking.reviewRating ??
                                  0)
                          ? Icons.star_rounded
                          : Icons
                              .star_border_rounded,
                      color:
                          AppColors.starYellow,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.reviewText
                    ?.trim()
                    .isNotEmpty ==
                true) ...<Widget>[
              const SizedBox(height: 9),
              Text(
                booking.reviewText!.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 1.5,
                  color:
                      AppColors.textMedium,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isMutating
            ? null
            : () {
                _openReviewDialog(
                  booking,
                );
              },
        icon: const Icon(
          Icons.star_rounded,
        ),
        label: Text(
          'Rate ${booking.counselorName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.starYellow,
          foregroundColor:
              AppColors.textDark,
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BookingModel booking) {
    if (booking.consultationStatus == 'pending_payment' &&
        booking.isPaymentWindowExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Batas pembayaran telah berakhir. Tekan refresh agar status dan slot diperbarui.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            height: 1.5,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (booking.canRetryPayment && booking.paymentId.isNotEmpty) {
      return Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMutating ? null : _continuePayment,
              icon: const Icon(Icons.payment_rounded),
              label: Text(
                booking.paymentStatus == 'rejected'
                    ? 'Upload Ulang Bukti Pembayaran'
                    : 'Continue to Payment',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: booking.canCancelBooking && !_isMutating
                  ? _cancelBooking
                  : null,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(
                'Cancel Booking',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Slot dicadangkan sampai ${_formatPaymentDeadline(booking)} WIB.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ],
      );
    }

    if (booking.isOffline &&
        (booking.consultationStatus == 'confirmed' || booking.consultationStatus == 'ongoing' || booking.consultationStatus == 'completed') &&
        booking.paymentStatus == 'paid') {
      if (booking.isActualAttendanceFinal) {
        final bool attended = booking.attendanceStatus == 'attended';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (attended ? AppColors.success : AppColors.error).withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              Icon(attended ? Icons.check_circle_rounded : Icons.person_off_rounded, color: attended ? AppColors.success : AppColors.error),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  attended
                      ? 'Counselor telah mencatat bahwa kamu hadir pada sesi offline.'
                      : 'Counselor telah mencatat bahwa kamu tidak hadir pada sesi offline.',
                  style: GoogleFonts.poppins(fontSize: 11, height: 1.5, color: attended ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }

      if (booking.isAttendanceConfirmed) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Kehadiran H-1 sudah dikonfirmasi. Status hadir aktual akan dicatat oleh counselor pada hari konsultasi.',
                  style: GoogleFonts.poppins(fontSize: 11, height: 1.5, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: booking.canConfirmOfflineAttendance && !_isMutating ? _confirmAttendance : null,
              icon: _isMutating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Icon(booking.canConfirmOfflineAttendance ? Icons.how_to_reg_rounded : Icons.lock_clock_rounded),
              label: Text(
                _isMutating
                    ? 'Confirming...'
                    : booking.isBeforeAttendanceWindow
                        ? 'Available on H-1'
                        : booking.isAttendanceWindowClosed
                            ? 'Confirmation Closed'
                            : 'Confirm Offline Attendance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.textLight.withOpacity(0.22),
                disabledForegroundColor: AppColors.textMedium,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _attendanceInformation(booking),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              height: 1.5,
              color: booking.canConfirmOfflineAttendance ? AppColors.primary : AppColors.textMedium,
            ),
          ),
        ],
      );
    }

    if (booking.isOnline &&
        booking.paymentStatus == 'paid' &&
        (booking.consultationStatus == 'confirmed' ||
            booking.consultationStatus == 'ongoing' ||
            booking.consultationStatus == 'completed')) {
      final DateTime now = DateTime.now();
      final bool beforeSession = now.isBefore(booking.scheduledStart);
      final bool duringSession =
          !beforeSession && now.isBefore(booking.scheduledEnd);
      final bool hasRoom =
          booking.chatRoomId != null && booking.chatRoomId!.isNotEmpty;

      if (!hasRoom) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'Room chat sedang disiapkan. Tekan refresh beberapa saat lagi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textMedium,
            ),
          ),
        );
      }

      return Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: beforeSession ? null : () => _openChat(booking),
              icon: Icon(
                beforeSession
                    ? Icons.lock_clock_rounded
                    : duringSession
                        ? Icons.chat_bubble_rounded
                        : Icons.history_rounded,
              ),
              label: Text(
                beforeSession
                    ? 'Room Chat Belum Aktif'
                    : duringSession
                        ? 'Go to Room Chat'
                        : 'View Chat History',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.textLight.withOpacity(0.22),
                disabledForegroundColor: AppColors.textMedium,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            beforeSession
                ? 'Room chat aktif pada '
                    '${DateFormat('d MMM yyyy, HH:mm').format(booking.scheduledStart)}.'
                : duringSession
                    ? 'Sesi chat aktif sampai '
                        '${DateFormat('HH:mm').format(booking.scheduledEnd)}.'
                    : 'Sesi telah selesai. Pesan hanya dapat dibaca.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              height: 1.5,
              color: AppColors.textMedium,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _attendanceInformation(
    BookingModel booking,
  ) {
    if (booking.attendanceStatus == 'attended') {
      return 'Counselor telah mencatat bahwa kamu hadir.';
    }

    if (booking.attendanceStatus == 'absent') {
      return 'Counselor telah mencatat bahwa kamu tidak hadir.';
    }

    if (booking.isAttendanceConfirmed) {
      return 'Kamu sudah mengonfirmasi rencana hadir. Kehadiran aktual akan dicatat counselor.';
    }

    if (booking.consultationStatus != 'confirmed' ||
        booking.paymentStatus != 'paid') {
      return 'Konfirmasi kehadiran tersedia setelah '
          'pembayaran disetujui admin.';
    }

    if (booking.isBeforeAttendanceWindow) {
      return 'Konfirmasi kehadiran dapat dilakukan mulai '
          '${_formatAttendanceOpenAt(booking)} WIB.';
    }

    if (booking.isAttendanceWindowClosed) {
      return 'Waktu konfirmasi kehadiran sudah berakhir '
          'karena jadwal konsultasi telah dimulai.';
    }

    return 'Konfirmasi bahwa kamu benar-benar akan hadir '
        'pada sesi konsultasi offline ini.';
  }

  String _formatPaymentDeadline(BookingModel booking) {
    return DateFormat('d MMMM yyyy, HH:mm').format(booking.paymentDeadline);
  }

  String _formatAttendanceOpenAt(
    BookingModel booking,
  ) {
    /*
     * Ubah ke wall-clock WIB untuk display.
     */
    final DateTime jakartaTime =
        booking.attendanceOpenAt
            .toUtc()
            .add(
              const Duration(hours: 7),
            );

    return DateFormat(
      'd MMMM yyyy, HH:mm',
    ).format(jakartaTime);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMedium,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            size: 50,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadBooking,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending_payment':
        return Icons.payment_rounded;
      case 'waiting_verification':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      case 'ongoing':
        return Icons.play_circle_fill_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
      case 'expired':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatCurrency(double value) {
    final String number = value.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();

    for (int index = 0; index < number.length; index++) {
      if (index > 0 && (number.length - index) % 3 == 0) {
        result.write('.');
      }
      result.write(number[index]);
    }

    return 'Rp$result';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

class _CancelBookingDialog
    extends StatefulWidget {
  const _CancelBookingDialog();

  @override
  State<_CancelBookingDialog> createState() =>
      _CancelBookingDialogState();
}

class _CancelBookingDialogState
    extends State<_CancelBookingDialog> {
  final TextEditingController _reasonController =
      TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _reasonController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
      title: Text(
        'Cancel Booking?',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Booking yang dibatalkan akan '
            'melepaskan slot agar dapat dipilih '
            'user lain.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.55,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText:
                  'Alasan pembatalan (opsional)',
              filled: true,
              fillColor:
                  AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Keep Booking'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Cancel Booking'),
        ),
      ],
    );
  }
}

