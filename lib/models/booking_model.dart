class BookingModel {
  final String consultationId;
  final String paymentId;
  final String slotId;
  final String counselorId;

  final String counselorName;
  final String specialization;
  final String location;
  final String? avatarPath;

  final String bookingCode;
  final String consultationType;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double amount;
  final String? notes;

  final String consultationStatus;
  final String paymentStatus;
  final String attendanceStatus;

  final String? paymentMethodId;
  final String? proofPath;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  final String? chatRoomId;

  const BookingModel({
    required this.consultationId,
    required this.paymentId,
    required this.slotId,
    required this.counselorId,
    required this.counselorName,
    required this.specialization,
    required this.location,
    required this.avatarPath,
    required this.bookingCode,
    required this.consultationType,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.amount,
    required this.notes,
    required this.consultationStatus,
    required this.paymentStatus,
    required this.attendanceStatus,
    required this.paymentMethodId,
    required this.proofPath,
    required this.rejectionReason,
    required this.submittedAt,
    required this.verifiedAt,
    required this.chatRoomId,
  });

  factory BookingModel.fromMergedMaps({
    required Map<String, dynamic> consultation,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? counselorProfile,
    Map<String, dynamic>? counselorDetail,
    Map<String, dynamic>? chatRoom,
  }) {
    return BookingModel(
      consultationId: consultation['id']?.toString() ?? '',
      paymentId: payment?['id']?.toString() ?? '',
      slotId: consultation['slot_id']?.toString() ?? '',
      counselorId: consultation['counselor_id']?.toString() ?? '',
      counselorName:
          counselorProfile?['full_name']?.toString().trim().isNotEmpty == true
              ? counselorProfile!['full_name'].toString().trim()
              : 'Counselor',
      specialization:
          counselorDetail?['specialization']?.toString().trim() ?? '',
      location: counselorDetail?['location']?.toString().trim() ?? '',
      avatarPath: counselorProfile?['avatar_path']?.toString(),
      bookingCode: consultation['booking_code']?.toString() ?? '-',
      consultationType:
          consultation['consultation_type']?.toString() ?? 'online',
      scheduledStart: _parseDateTime(consultation['scheduled_start']),
      scheduledEnd: _parseDateTime(consultation['scheduled_end']),
      amount: _parseDouble(consultation['amount']),
      notes: consultation['notes']?.toString(),
      consultationStatus:
          consultation['status']?.toString() ?? 'pending_payment',
      paymentStatus: payment?['status']?.toString() ?? 'unpaid',
      attendanceStatus:
          consultation['attendance_status']?.toString() ?? 'not_required',
      paymentMethodId: payment?['method_id']?.toString(),
      proofPath: payment?['proof_path']?.toString(),
      rejectionReason: payment?['rejection_reason']?.toString(),
      submittedAt: _parseNullableDateTime(payment?['submitted_at']),
      verifiedAt: _parseNullableDateTime(payment?['verified_at']),
      chatRoomId: chatRoom?['id']?.toString(),
    );
  }

  bool get isOnline => consultationType == 'online';
  bool get isOffline => consultationType == 'offline';

  bool get isConfirmed =>
      consultationStatus == 'confirmed' ||
      consultationStatus == 'ongoing' ||
      consultationStatus == 'completed';

  bool get isWaitingForPayment => consultationStatus == 'pending_payment';

  bool get isWaitingForVerification =>
      consultationStatus == 'waiting_verification';

  bool get canRetryPayment =>
      consultationStatus == 'pending_payment' &&
      (paymentStatus == 'unpaid' || paymentStatus == 'rejected');


  bool get isAttendanceConfirmed =>
      attendanceStatus == 'confirmed';

  DateTime get attendanceOpenAt {
    /*
     * Backend memakai Asia/Jakarta.
     * Perhitungan ini menghasilkan pukul 00.00 WIB pada H-1
     * tanpa membutuhkan package timezone tambahan.
     */
    final DateTime jakartaSchedule =
        scheduledStart.toUtc().add(
          const Duration(hours: 7),
        );

    final DateTime scheduleDateUtc = DateTime.utc(
      jakartaSchedule.year,
      jakartaSchedule.month,
      jakartaSchedule.day,
    );

    return scheduleDateUtc
        .subtract(
          const Duration(
            days: 1,
            hours: 7,
          ),
        )
        .toLocal();
  }

  bool get isBeforeAttendanceWindow {
    return DateTime.now()
        .toUtc()
        .isBefore(
          attendanceOpenAt.toUtc(),
        );
  }

  bool get isAttendanceWindowOpen {
    final DateTime now =
        DateTime.now().toUtc();

    return !now.isBefore(
          attendanceOpenAt.toUtc(),
        ) &&
        now.isBefore(
          scheduledStart.toUtc(),
        );
  }

  bool get isAttendanceWindowClosed {
    return !DateTime.now()
        .toUtc()
        .isBefore(
          scheduledStart.toUtc(),
        );
  }

  bool get canConfirmOfflineAttendance {
    return isOffline &&
        consultationStatus == 'confirmed' &&
        paymentStatus == 'paid' &&
        attendanceStatus == 'not_confirmed' &&
        isAttendanceWindowOpen;
  }

  String get attendanceStatusLabel {
    switch (attendanceStatus) {
      case 'not_required':
        return 'Tidak Diperlukan';
      case 'not_confirmed':
        return 'Belum Dikonfirmasi';
      case 'confirmed':
        return 'Sudah Dikonfirmasi';
      case 'attended':
        return 'Hadir';
      case 'absent':
        return 'Tidak Hadir';
      default:
        return attendanceStatus;
    }
  }

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
      default:
        return consultationStatus;
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
      default:
        return paymentStatus;
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
