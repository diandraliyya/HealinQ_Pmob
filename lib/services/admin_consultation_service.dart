import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_consultation_model.dart';

class AdminConsultationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdminConsultationModel>> getAllConsultations() async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      await _expireStaleBookingsQuietly();

      final List<dynamic> consultationRows = await _client
          .from('consultations')
          .select(
            'id, booking_code, user_id, counselor_id, slot_id, '
            'consultation_type, scheduled_start, scheduled_end, amount, '
            'notes, status, attendance_status, attendance_confirmed_at, '
            'attendance_marked_at, attendance_marked_by, created_at, updated_at',
          )
          .order('created_at', ascending: false);

      if (consultationRows.isEmpty) {
        return <AdminConsultationModel>[];
      }

      final List<Map<String, dynamic>> consultations = consultationRows
          .map(
            (dynamic row) => Map<String, dynamic>.from(row as Map),
          )
          .toList();

      final List<String> consultationIds = consultations
          .map((Map<String, dynamic> row) => row['id']?.toString() ?? '')
          .where((String id) => id.isNotEmpty)
          .toList();

      final Set<String> profileIds = <String>{};

      for (final Map<String, dynamic> row in consultations) {
        final String userId = row['user_id']?.toString() ?? '';
        final String counselorId = row['counselor_id']?.toString() ?? '';

        if (userId.isNotEmpty) profileIds.add(userId);
        if (counselorId.isNotEmpty) profileIds.add(counselorId);
      }

      final List<dynamic> paymentRows = await _client
          .from('payments')
          .select(
            'id, consultation_id, method_id, amount, proof_path, status, '
            'submitted_at, verified_at, rejection_reason, created_at',
          )
          .inFilter('consultation_id', consultationIds);

      final List<dynamic> profileRows = profileIds.isEmpty
          ? <dynamic>[]
          : await _client
              .from('profiles')
              .select('id, full_name, email, role, status')
              .inFilter('id', profileIds.toList());

      final Set<String> counselorIds = consultations
          .map(
            (Map<String, dynamic> row) =>
                row['counselor_id']?.toString() ?? '',
          )
          .where((String id) => id.isNotEmpty)
          .toSet();

      final List<dynamic> counselorDetailRows = counselorIds.isEmpty
          ? <dynamic>[]
          : await _client
              .from('counselor_profiles')
              .select('id, specialization')
              .inFilter('id', counselorIds.toList());

      final Set<String> methodIds = paymentRows
          .map(
            (dynamic row) =>
                (row as Map)['method_id']?.toString() ?? '',
          )
          .where((String id) => id.isNotEmpty)
          .toSet();

      final List<dynamic> methodRows = methodIds.isEmpty
          ? <dynamic>[]
          : await _client
              .from('payment_methods')
              .select('id, name, method_type')
              .inFilter('id', methodIds.toList());

      final Map<String, Map<String, dynamic>> paymentByConsultation =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in paymentRows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map);
        final String consultationId =
            row['consultation_id']?.toString() ?? '';

        if (consultationId.isNotEmpty) {
          paymentByConsultation[consultationId] = row;
        }
      }

      final Map<String, Map<String, dynamic>> profileById =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in profileRows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map);
        final String id = row['id']?.toString() ?? '';
        if (id.isNotEmpty) profileById[id] = row;
      }

      final Map<String, Map<String, dynamic>> counselorDetailById =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in counselorDetailRows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map);
        final String id = row['id']?.toString() ?? '';
        if (id.isNotEmpty) counselorDetailById[id] = row;
      }

      final Map<String, Map<String, dynamic>> methodById =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in methodRows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map);
        final String id = row['id']?.toString() ?? '';
        if (id.isNotEmpty) methodById[id] = row;
      }

      return consultations.map((Map<String, dynamic> consultation) {
        final String consultationId =
            consultation['id']?.toString() ?? '';
        final String userId = consultation['user_id']?.toString() ?? '';
        final String counselorId =
            consultation['counselor_id']?.toString() ?? '';

        final Map<String, dynamic>? payment =
            paymentByConsultation[consultationId];
        final Map<String, dynamic>? userProfile = profileById[userId];
        final Map<String, dynamic>? counselorProfile =
            profileById[counselorId];
        final Map<String, dynamic>? counselorDetail =
            counselorDetailById[counselorId];
        final String methodId = payment?['method_id']?.toString() ?? '';
        final Map<String, dynamic>? method = methodById[methodId];

        return AdminConsultationModel(
          consultationId: consultationId,
          paymentId: payment?['id']?.toString() ?? '',
          slotId: consultation['slot_id']?.toString() ?? '',
          userId: userId,
          counselorId: counselorId,
          userName: userProfile?['full_name']?.toString() ?? 'User',
          userEmail: userProfile?['email']?.toString() ?? '-',
          counselorName:
              counselorProfile?['full_name']?.toString() ?? 'Counselor',
          specialization:
              counselorDetail?['specialization']?.toString() ?? '-',
          bookingCode: consultation['booking_code']?.toString() ?? '-',
          consultationType:
              consultation['consultation_type']?.toString() ?? 'online',
          scheduledStart:
              AdminConsultationModel.parseDate(
            consultation['scheduled_start'],
          ),
          scheduledEnd:
              AdminConsultationModel.parseDate(
            consultation['scheduled_end'],
          ),
          amount:
              AdminConsultationModel.parseDouble(consultation['amount']),
          notes: consultation['notes']?.toString(),
          consultationStatus:
              consultation['status']?.toString() ?? 'pending_payment',
          paymentStatus: payment?['status']?.toString() ?? 'unpaid',
          attendanceStatus:
              consultation['attendance_status']?.toString() ?? 'not_required',
          attendanceConfirmedAt: AdminConsultationModel.parseNullableDate(consultation['attendance_confirmed_at']),
          attendanceMarkedAt: AdminConsultationModel.parseNullableDate(consultation['attendance_marked_at']),
          attendanceMarkedBy: consultation['attendance_marked_by']?.toString(),
          paymentMethodName: method?['name']?.toString(),
          proofPath: payment?['proof_path']?.toString(),
          rejectionReason: payment?['rejection_reason']?.toString(),
          submittedAt: AdminConsultationModel.parseNullableDate(
            payment?['submitted_at'],
          ),
          verifiedAt: AdminConsultationModel.parseNullableDate(
            payment?['verified_at'],
          ),
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> approvePayment(String paymentId) async {
    await _reviewPayment(
      paymentId: paymentId,
      approve: true,
      rejectionReason: null,
    );
  }

  Future<void> rejectPayment({
    required String paymentId,
    required String reason,
  }) async {
    final String cleanedReason = reason.trim();

    if (cleanedReason.isEmpty) {
      throw Exception('Alasan penolakan wajib diisi.');
    }

    await _reviewPayment(
      paymentId: paymentId,
      approve: false,
      rejectionReason: cleanedReason,
    );
  }

  Future<void> _reviewPayment({
    required String paymentId,
    required bool approve,
    required String? rejectionReason,
  }) async {
    if (_client.auth.currentSession == null) {
      throw Exception(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      await _client.rpc(
        'review_payment',
        params: <String, dynamic>{
          'p_payment_id': paymentId,
          'p_approve': approve,
          'p_rejection_reason': rejectionReason,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<String?> getPaymentProofUrl(String? proofPath) async {
    if (proofPath == null || proofPath.trim().isEmpty) return null;

    try {
      return await _client.storage
          .from('payment-proofs')
          .createSignedUrl(proofPath, 600);
    } on StorageException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<void> _expireStaleBookingsQuietly() async {
    try {
      await _client.rpc(
        'expire_stale_consultation_bookings',
        params: <String, dynamic>{'p_limit': 200},
      );
    } catch (_) {
      // pg_cron tetap menjadi jalur utama.
    }
  }

  String _translateError(PostgrestException error) {
    final String message =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();

    if (message.contains('only an active admin')) {
      return 'Hanya admin aktif yang dapat memverifikasi pembayaran.';
    }

    if (message.contains('payment not found')) {
      return 'Data pembayaran tidak ditemukan.';
    }

    if (message.contains('rejection reason is required')) {
      return 'Alasan penolakan wajib diisi.';
    }

    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Akunmu tidak memiliki izin untuk mengakses data pembayaran.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat memproses pembayaran.'
        : error.message.trim();
  }

  String _cleanError(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }
}
