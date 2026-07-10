import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import 'booking_ticket_screen.dart';
import 'payment_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _service = BookingService();

  List<BookingModel> _bookings = <BookingModel>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<BookingModel> result = await _service.getMyBookings();

      if (!mounted) return;

      setState(() {
        _bookings = result;
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

  List<BookingModel> get _visibleBookings {
    switch (_selectedFilter) {
      case 'verification':
        return _bookings
            .where((BookingModel item) => item.isWaitingForVerification)
            .toList();
      case 'confirmed':
        return _bookings
            .where((BookingModel item) => item.isConfirmed)
            .toList();
      case 'payment':
        return _bookings
            .where((BookingModel item) => item.canRetryPayment)
            .toList();
      case 'all':
      default:
        return _bookings;
    }
  }

  int get _verificationCount => _bookings
      .where((BookingModel item) => item.isWaitingForVerification)
      .length;

  int get _confirmedCount =>
      _bookings.where((BookingModel item) => item.isConfirmed).length;

  int get _paymentCount =>
      _bookings.where((BookingModel item) => item.canRetryPayment).length;

  Future<void> _openTicket(BookingModel booking) async {
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

  Future<void> _continuePayment(BookingModel booking) async {
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
      await _loadBookings(showLoading: false);
    }
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
                  onRefresh: () => _loadBookings(showLoading: false),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'My Bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Pantau pembayaran dan status konsultasimu.',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadBookings,
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: <Widget>[
        _buildStats(),
        const SizedBox(height: 16),
        _buildFilter(),
        const SizedBox(height: 14),
        if (_visibleBookings.isEmpty)
          _buildEmptyState()
        else
          ..._visibleBookings.map(_buildBookingCard),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _statCard(
            title: 'Total',
            value: '${_bookings.length}',
            icon: Icons.receipt_long_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            title: 'Verifikasi',
            value: '$_verificationCount',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFD68A1F),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            title: 'Confirmed',
            value: '$_confirmedCount',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _filterChip('all', 'All (${_bookings.length})'),
          _filterChip('verification', 'Verification ($_verificationCount)'),
          _filterChip('payment', 'Payment ($_paymentCount)'),
          _filterChip('confirmed', 'Confirmed ($_confirmedCount)'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
        side: BorderSide.none,
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final Color statusColor = _consultationStatusColor(
      booking.consultationStatus,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 25,
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
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.counselorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${booking.specialization} • ${booking.consultationType.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
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
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  booking.consultationStatusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: <Widget>[
                _infoRow(
                  Icons.confirmation_number_rounded,
                  booking.bookingCode,
                ),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.calendar_today_rounded,
                  DateFormat('d MMM yyyy, HH:mm').format(
                    booking.scheduledStart,
                  ),
                ),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.payments_rounded,
                  '${_formatCurrency(booking.amount)} • ${booking.paymentStatusLabel}',
                ),
              ],
            ),
          ),
          if (booking.paymentStatus == 'rejected') ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Pembayaran ditolak: '
                '${booking.rejectionReason?.trim().isNotEmpty == true ? booking.rejectionReason : 'Silakan unggah ulang bukti pembayaran.'}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  height: 1.5,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openTicket(booking),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'View Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (booking.canRetryPayment && booking.paymentId.isNotEmpty) ...<Widget>[
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _continuePayment(booking),
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text(
                      booking.paymentStatus == 'rejected'
                          ? 'Upload Ulang'
                          : 'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.receipt_long_outlined,
            size: 54,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No bookings found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'all'
                ? 'Kamu belum memiliki riwayat konsultasi.'
                : 'Tidak ada booking pada kategori ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
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
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _consultationStatusColor(String status) {
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
