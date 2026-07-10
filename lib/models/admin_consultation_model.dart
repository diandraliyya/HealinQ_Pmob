class AdminConsultationModel {
  final String consultationId;
  final String paymentId;
  final String slotId;
  final String userId;
  final String counselorId;

  final String userName;
  final String userEmail;
  final String counselorName;
  final String specialization;

  final String bookingCode;
  final String consultationType;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double amount;
  final String? notes;

  final String consultationStatus;
  final String paymentStatus;
  final String attendanceStatus;

  final String? paymentMethodName;
  final String? proofPath;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  const AdminConsultationModel({
    required this.consultationId,
    required this.paymentId,
    required this.slotId,
    required this.userId,
    required this.counselorId,
    required this.userName,
    required this.userEmail,
    required this.counselorName,
    required this.specialization,
    required this.bookingCode,
    required this.consultationType,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.amount,
    required this.notes,
    required this.consultationStatus,
    required this.paymentStatus,
    required this.attendanceStatus,
    required this.paymentMethodName,
    required this.proofPath,
    required this.rejectionReason,
    required this.submittedAt,
    required this.verifiedAt,
  });

  bool get isWaitingVerification =>
      paymentStatus == 'pending_verification' &&
      consultationStatus == 'waiting_verification';

  String get consultationStatusLabel {
    switch (consultationStatus) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'waiting_verification':
        return 'Menunggu Verifikasi';
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

  static DateTime parseDate(dynamic value) {
    return DateTime.parse(value.toString()).toLocal();
  }

  static DateTime? parseNullableDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
