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
  final DateTime? attendanceConfirmedAt;
  final DateTime? attendanceMarkedAt;
  final String? attendanceMarkedBy;
  final String? paymentMethodId;
  final String? proofPath;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime consultationCreatedAt;
  final DateTime? paymentUpdatedAt;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? chatRoomId;
  final String? reviewId;
  final int? reviewRating;
  final String? reviewText;
  final DateTime? reviewedAt;

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
    required this.attendanceConfirmedAt,
    required this.attendanceMarkedAt,
    required this.attendanceMarkedBy,
    required this.paymentMethodId,
    required this.proofPath,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.consultationCreatedAt,
    required this.paymentUpdatedAt,
    required this.submittedAt,
    required this.verifiedAt,
    required this.chatRoomId,
    this.reviewId,
    this.reviewRating,
    this.reviewText,
    this.reviewedAt,
  });

  factory BookingModel.fromMergedMaps({
    required Map<String, dynamic> consultation,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? counselorProfile,
    Map<String, dynamic>? counselorDetail,
    Map<String, dynamic>? chatRoom,
    Map<String, dynamic>? review,
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
      attendanceConfirmedAt:
          _parseNullableDateTime(consultation['attendance_confirmed_at']),
      attendanceMarkedAt:
          _parseNullableDateTime(consultation['attendance_marked_at']),
      attendanceMarkedBy: consultation['attendance_marked_by']?.toString(),
      paymentMethodId: payment?['method_id']?.toString(),
      proofPath: payment?['proof_path']?.toString(),
      rejectionReason: payment?['rejection_reason']?.toString(),
      cancellationReason: consultation['cancellation_reason']?.toString(),
      consultationCreatedAt: _parseDateTime(consultation['created_at']),
      paymentUpdatedAt: _parseNullableDateTime(payment?['updated_at']),
      submittedAt: _parseNullableDateTime(payment?['submitted_at']),
      verifiedAt: _parseNullableDateTime(payment?['verified_at']),
      chatRoomId: chatRoom?['id']?.toString(),
      reviewId: review?['id']?.toString(),
      reviewRating: _parseNullableInt(review?['rating']),
      reviewText: review?['review_text']?.toString(),
      reviewedAt: _parseNullableDateTime(review?['created_at']),
    );
  }

  bool get isOnline => consultationType == 'online';
  bool get isOffline => consultationType == 'offline';

  bool get hasReview => reviewId != null && reviewId!.isNotEmpty;

  bool get canReviewCounselor =>
      consultationStatus == 'completed' &&
      paymentStatus == 'paid' &&
      !hasReview &&
      (isOnline || attendanceStatus == 'attended');

  bool get isConfirmed =>
      consultationStatus == 'confirmed' ||
      consultationStatus == 'ongoing' ||
      consultationStatus == 'completed';

  bool get isWaitingForPayment => consultationStatus == 'pending_payment';
  bool get isWaitingForVerification =>
      consultationStatus == 'waiting_verification';

  DateTime get paymentWindowStartedAt =>
      paymentUpdatedAt ?? consultationCreatedAt;

  DateTime get paymentDeadline {
    final DateTime regularDeadline =
        paymentWindowStartedAt.add(const Duration(minutes: 30));
    return regularDeadline.isBefore(scheduledStart)
        ? regularDeadline
        : scheduledStart;
  }

  bool get isPaymentWindowExpired => !DateTime.now().isBefore(paymentDeadline);

  bool get canRetryPayment =>
      consultationStatus == 'pending_payment' &&
      (paymentStatus == 'unpaid' || paymentStatus == 'rejected') &&
      !isPaymentWindowExpired;

  bool get canCancelBooking =>
      consultationStatus == 'pending_payment' &&
      (paymentStatus == 'unpaid' || paymentStatus == 'rejected') &&
      !isPaymentWindowExpired;

  bool get isAttendanceConfirmed => attendanceConfirmedAt != null;

  bool get isActualAttendanceFinal =>
      attendanceStatus == 'attended' || attendanceStatus == 'absent';

  String get userConfirmationLabel {
    if (!isOffline) return 'Tidak Diperlukan';
    return attendanceConfirmedAt != null
        ? 'Sudah Konfirmasi H-1'
        : 'Belum Konfirmasi H-1';
  }

  String get actualAttendanceLabel {
    switch (attendanceStatus) {
      case 'attended':
        return 'Hadir';
      case 'absent':
        return 'Tidak Hadir';
      default:
        return 'Belum Dicatat Counselor';
    }
  }

  DateTime get attendanceOpenAt {
    final DateTime jakartaSchedule =
        scheduledStart.toUtc().add(const Duration(hours: 7));
    final DateTime scheduleDateUtc = DateTime.utc(
      jakartaSchedule.year,
      jakartaSchedule.month,
      jakartaSchedule.day,
    );
    return scheduleDateUtc
        .subtract(const Duration(days: 1, hours: 7))
        .toLocal();
  }

  bool get isBeforeAttendanceWindow =>
      DateTime.now().toUtc().isBefore(attendanceOpenAt.toUtc());

  bool get isAttendanceWindowOpen {
    final DateTime now = DateTime.now().toUtc();
    return !now.isBefore(attendanceOpenAt.toUtc()) &&
        now.isBefore(scheduledStart.toUtc());
  }

  bool get isAttendanceWindowClosed =>
      !DateTime.now().toUtc().isBefore(scheduledStart.toUtc());

  bool get canConfirmOfflineAttendance =>
      isOffline &&
      consultationStatus == 'confirmed' &&
      paymentStatus == 'paid' &&
      attendanceStatus == 'not_confirmed' &&
      isAttendanceWindowOpen;

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

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
