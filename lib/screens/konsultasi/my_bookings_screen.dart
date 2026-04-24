import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../chat/room_chat_screen.dart';
import 'booking_ticket_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final consultations = context.watch<AppState>().consultations;

    final sortedConsultations = List<ConsultationModel>.from(consultations)
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        'My Bookings',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lihat semua tiket konsultasi online dan offline kamu.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: sortedConsultations.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: sortedConsultations.length,
                        itemBuilder: (context, index) {
                          final consultation = sortedConsultations[index];

                          return _BookingCard(
                            consultation: consultation,
                            onViewTicket: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookingTicketScreen(
                                    consultation: consultation,
                                    isOffline:
                                        consultation.type.toLowerCase() ==
                                            'offline',
                                    fromMyBookings: true,
                                  ),
                                ),
                              );
                            },
                            onOpenChat: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RoomChatScreen(
                                    counselor: consultation.counselor,
                                    consultation: consultation,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
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
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 14),
            Text(
              'No bookings yet',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kamu belum memiliki tiket konsultasi. Silakan booking konsultasi terlebih dahulu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                'Book Consultation',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback onViewTicket;
  final VoidCallback onOpenChat;

  const _BookingCard({
    required this.consultation,
    required this.onViewTicket,
    required this.onOpenChat,
  });

  bool get _isOffline => consultation.type.toLowerCase() == 'offline';
  bool get _isOnline => consultation.type.toLowerCase() == 'online';

  DateTime get _sessionStart => consultation.scheduledAt;
  DateTime get _sessionEnd => consultation.scheduledAt.add(
        const Duration(hours: 1),
      );

  bool get _isConfirmed => consultation.status == 'Confirmed';

  bool get _isBeforeSession {
    final now = DateTime.now();
    return now.isBefore(_sessionStart);
  }

  bool get _isDuringSession {
    final now = DateTime.now();
    return (now.isAtSameMomentAs(_sessionStart) ||
            now.isAfter(_sessionStart)) &&
        now.isBefore(_sessionEnd);
  }

  bool get _isSessionEnded {
    final now = DateTime.now();
    return now.isAtSameMomentAs(_sessionEnd) || now.isAfter(_sessionEnd);
  }

  bool get _canOpenChat {
    return _isOnline && _isConfirmed && _isDuringSession;
  }

  String get _chatButtonText {
    if (_isOffline) return 'Offline Ticket';

    if (!_isConfirmed) {
      return 'Need Confirm';
    }

    if (_isBeforeSession) {
      return 'Not Started';
    }

    if (_isSessionEnded) {
      return 'Session Ended';
    }

    return 'Open Chat';
  }

  IconData get _chatButtonIcon {
    if (!_isConfirmed) return Icons.lock_outline_rounded;
    if (_isBeforeSession) return Icons.lock_clock_rounded;
    if (_isSessionEnded) return Icons.event_busy_rounded;
    return Icons.chat_bubble_rounded;
  }

  Color get _chatButtonColor {
    if (_canOpenChat) return AppColors.primary;
    return AppColors.textLight.withOpacity(0.18);
  }

  Color get _chatButtonTextColor {
    if (_canOpenChat) return AppColors.white;
    return AppColors.textMedium;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, d MMM yyyy').format(
      consultation.scheduledAt,
    );
    final timeText = DateFormat('HH.00').format(consultation.scheduledAt);
    final endText = DateFormat('HH.00').format(_sessionEnd);
    final statusColor = _statusColor(consultation.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    _isOffline ? AppColors.primarySoft : AppColors.secondaryLight,
                child: Icon(
                  _isOffline ? Icons.people_rounded : Icons.chat_bubble_rounded,
                  color: _isOffline ? AppColors.primary : AppColors.teal,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.counselor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${consultation.counselor.specialization} • ${consultation.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  consultation.status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
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
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dateText • $timeText-$endText WIB',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isOffline) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      consultation.counselor.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isOnline) ...[
            const SizedBox(height: 8),
            _buildOnlineSessionInfo(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewTicket,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    'View Ticket',
                    style: GoogleFonts.poppins(
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
              if (_isOnline) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canOpenChat
                        ? onOpenChat
                        : () => _showCannotOpenChat(context),
                    icon: Icon(_chatButtonIcon, size: 18),
                    label: Text(
                      _chatButtonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _chatButtonColor,
                      foregroundColor: _chatButtonTextColor,
                      disabledBackgroundColor: AppColors.textLight.withOpacity(0.18),
                      disabledForegroundColor: AppColors.textMedium,
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

  Widget _buildOnlineSessionInfo() {
    String text;
    IconData icon;
    Color color;

    if (!_isConfirmed) {
      text = 'Belum dikonfirmasi. Buka ticket saat jadwal mulai untuk konfirmasi.';
      icon = Icons.lock_outline_rounded;
      color = AppColors.textMedium;
    } else if (_isBeforeSession) {
      text = 'Sudah confirmed, tetapi sesi chat belum dimulai.';
      icon = Icons.lock_clock_rounded;
      color = AppColors.textMedium;
    } else if (_isSessionEnded) {
      text = 'Sesi online sudah selesai. Room chat tidak bisa dibuka lagi.';
      icon = Icons.event_busy_rounded;
      color = AppColors.error;
    } else {
      text = 'Sesi sedang berlangsung. Kamu bisa membuka room chat.';
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCannotOpenChat(BuildContext context) {
    String message;

    if (!_isConfirmed) {
      message =
          'Konsultasi online belum dikonfirmasi. Buka View Ticket saat jadwal sudah mulai untuk konfirmasi.';
    } else if (_isBeforeSession) {
      message = 'Room chat belum bisa dibuka karena jadwal sesi belum dimulai.';
    } else if (_isSessionEnded) {
      message = 'Sesi konsultasi sudah selesai. Room chat tidak bisa dibuka lagi.';
    } else {
      message = 'Room chat belum bisa dibuka.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return AppColors.success;
      case 'Pending':
        return const Color(0xFFD68A1F);
      case 'Completed':
        return AppColors.brandBlue;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}