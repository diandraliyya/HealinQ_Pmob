class CounselorScheduleData {
  final String counselorName;
  final String accountStatus;
  final bool offersOnline;
  final bool offersOffline;
  final List<CounselorScheduleItemModel> items;

  const CounselorScheduleData({
    required this.counselorName,
    required this.accountStatus,
    required this.offersOnline,
    required this.offersOffline,
    required this.items,
  });
}

class CounselorScheduleItemModel {
  final String slotId;
  final String counselorId;
  final String consultationType;
  final DateTime startAt;
  final DateTime endAt;
  final String slotStatus;

  final String? consultationId;
  final String? bookingCode;
  final String? consultationStatus;
  final String? attendanceStatus;
  final String? notes;
  final double amount;

  final String? paymentId;
  final String? paymentStatus;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const CounselorScheduleItemModel({
    required this.slotId,
    required this.counselorId,
    required this.consultationType,
    required this.startAt,
    required this.endAt,
    required this.slotStatus,
    required this.consultationId,
    required this.bookingCode,
    required this.consultationStatus,
    required this.attendanceStatus,
    required this.notes,
    required this.amount,
    required this.paymentId,
    required this.paymentStatus,
    required this.submittedAt,
    required this.verifiedAt,
    required this.rejectionReason,
  });

  factory CounselorScheduleItemModel.fromMergedMaps({
    required Map<String, dynamic> slot,
    Map<String, dynamic>? consultation,
    Map<String, dynamic>? payment,
  }) {
    return CounselorScheduleItemModel(
      slotId: slot['id']?.toString() ?? '',
      counselorId: slot['counselor_id']?.toString() ?? '',
      consultationType:
          slot['consultation_type']?.toString() ?? 'online',
      startAt: _parseDateTime(slot['start_at']),
      endAt: _parseDateTime(slot['end_at']),
      slotStatus: slot['status']?.toString() ?? 'available',
      consultationId: consultation?['id']?.toString(),
      bookingCode: consultation?['booking_code']?.toString(),
      consultationStatus: consultation?['status']?.toString(),
      attendanceStatus:
          consultation?['attendance_status']?.toString(),
      notes: consultation?['notes']?.toString(),
      amount: _parseDouble(consultation?['amount']),
      paymentId: payment?['id']?.toString(),
      paymentStatus: payment?['status']?.toString(),
      submittedAt:
          _parseNullableDateTime(payment?['submitted_at']),
      verifiedAt:
          _parseNullableDateTime(payment?['verified_at']),
      rejectionReason: payment?['rejection_reason']?.toString(),
    );
  }

  bool get isOnline => consultationType == 'online';
  bool get isOffline => consultationType == 'offline';

  bool get isPast => !endAt.isAfter(DateTime.now());

  bool get hasConsultation =>
      consultationId != null && consultationId!.isNotEmpty;

  bool get isReserved =>
      slotStatus == 'booked' && !isPast;

  bool get canBeModified =>
      slotStatus == 'available' &&
      startAt.isAfter(DateTime.now());

  int get durationMinutes =>
      endAt.difference(startAt).inMinutes;

  String get consultationStatusLabel {
    switch (consultationStatus) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'waiting_verification':
        return 'Menunggu Verifikasi Admin';
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'ongoing':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'expired':
        return 'Kedaluwarsa';
      case null:
        return slotStatus == 'booked'
            ? 'Dicadangkan'
            : slotStatus;
      default:
        return consultationStatus!;
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Belum Dibayar';
      case 'pending_verification':
        return 'Menunggu Verifikasi';
      case 'paid':
        return 'Lunas';
      case 'rejected':
        return 'Ditolak';
      case 'expired':
        return 'Kedaluwarsa';
      case null:
        return '-';
      default:
        return paymentStatus!;
    }
  }

  String get attendanceStatusLabel {
    switch (attendanceStatus) {
      case 'not_required':
        return 'Tidak Diperlukan';
      case 'not_confirmed':
        return 'Belum Dikonfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'attended':
        return 'Hadir';
      case 'absent':
        return 'Tidak Hadir';
      case null:
        return '-';
      default:
        return attendanceStatus!;
    }
  }

  String get displayStatusLabel {
    if (slotStatus == 'available') {
      return isPast ? 'Past' : 'Available';
    }

    if (slotStatus == 'blocked') {
      return isPast ? 'Past' : 'Blocked';
    }

    if (slotStatus == 'booked') {
      return consultationStatusLabel;
    }

    return slotStatus;
  }

  String get reservationDescription {
    switch (consultationStatus) {
      case 'pending_payment':
        if (paymentStatus == 'rejected') {
          return 'Bukti pembayaran ditolak. Slot tetap dicadangkan '
              'agar user dapat mengunggah ulang bukti pembayaran.';
        }
        return 'Slot telah dicadangkan, tetapi user belum '
            'mengirim bukti pembayaran.';
      case 'waiting_verification':
        return 'Bukti pembayaran sudah dikirim dan sedang '
            'menunggu verifikasi admin.';
      case 'confirmed':
        return 'Pembayaran sudah disetujui admin dan '
            'jadwal konsultasi telah terkonfirmasi.';
      case 'ongoing':
        return 'Sesi konsultasi sedang berlangsung.';
      case 'completed':
        return 'Sesi konsultasi telah selesai.';
      case 'cancelled':
        return 'Booking telah dibatalkan.';
      case 'expired':
        return 'Booking telah kedaluwarsa.';
      default:
        return slotStatus == 'booked'
            ? 'Slot telah dicadangkan oleh sebuah booking.'
            : 'Slot belum memiliki booking.';
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.parse(value.toString()).toLocal();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
