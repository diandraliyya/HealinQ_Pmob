import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../chat/message_list_screen.dart';

class BookingTicketScreen extends StatefulWidget {
  final ConsultationModel consultation;
  final bool isOffline;

  const BookingTicketScreen({super.key, required this.consultation, required this.isOffline});

  @override
  State<BookingTicketScreen> createState() => _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen> {
  bool _isConfirmed = false;
  Duration _timeRemaining = const Duration(hours: 1, minutes: 42, seconds: 17);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() => _timeRemaining -= const Duration(seconds: 1));
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.consultation;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(c.scheduledAt);
    final endHour = c.scheduledAt.add(const Duration(hours: 1));
    final timeStr = '${DateFormat('HH.00').format(c.scheduledAt)}-${DateFormat('HH.00').format(endHour)} WIB';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFB2EBF2), Color(0xFFFCE4EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary)),
                    Expanded(child: Text('Konsultasi', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    const ScoreCard(xp: 1240),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Ticket
                      _buildTicket(c, dateStr, timeStr),
                      const SizedBox(height: 24),
                      Text('Your session will be started at:', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium)),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_timeRemaining),
                        style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      if (!_isConfirmed)
                        GestureDetector(
                          onTap: () => setState(() => _isConfirmed = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text('Konfirmasi', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessageListScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(30)),
                            child: Text('Go to Room Chat', style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                        ),
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

  Widget _buildTicket(ConsultationModel c, String dateStr, String timeStr) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Ticket header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: _isConfirmed
                ? Text('Booking confirmed!', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16))
                : const SizedBox(height: 4),
          ),
          // Ticket content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Counselor info
                Row(
                  children: [
                    const CircleAvatar(radius: 28, backgroundColor: AppColors.secondaryLight, child: Icon(Icons.person, color: AppColors.teal, size: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.counselor.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${c.counselor.specialization} | ${c.type}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                              Text(' Verified', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFFFB6C1)),
                const SizedBox(height: 16),
                // Date and Time
                Row(
                  children: [
                    Expanded(child: _infoBox(Icons.calendar_today_rounded, 'Tanggal', dateStr, AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoBox(Icons.access_time_rounded, 'Time Session', timeStr, AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                _fullInfoBox(Icons.confirmation_number_rounded, 'Booking Code', c.bookingCode),
                const SizedBox(height: 8),
                if (widget.isOffline)
                  _fullInfoBox(Icons.location_on_rounded, 'Location', c.counselor.location),
                const SizedBox(height: 8),
                _fullInfoBox(Icons.chat_bubble_outline_rounded, 'Consultation Preview', c.notes?.isNotEmpty == true ? c.notes! : ''),
              ],
            ),
          ),
          // Dashed separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFB2EBF2), shape: BoxShape.circle)),
                Expanded(child: CustomPaint(painter: _DashedLinePainter())),
                Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFCE4EC), shape: BoxShape.circle)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium))]),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _fullInfoBox(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.primary, size: 14), const SizedBox(width: 4), Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium))]),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB6C1)..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 6, size.height / 2), paint);
      x += 10;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
