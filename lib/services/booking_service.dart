import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_model.dart';

class BookingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BookingModel>> getMyBookings() async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      final List<dynamic> consultationRows = await _client
          .from('consultations')
          .select(
            'id, booking_code, user_id, counselor_id, slot_id, '
            'consultation_type, scheduled_start, scheduled_end, amount, '
            'notes, status, attendance_status, confirmed_at, '
            'attendance_confirmed_at, completed_at, cancelled_at, '
            'cancellation_reason, created_at, updated_at',
          )
          .eq('user_id', user.id)
          .order('scheduled_start', ascending: false);

      return _mergeBookings(consultationRows);
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<BookingModel> getBookingById(
    String consultationId,
  ) async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      final List<dynamic> consultationRows = await _client
          .from('consultations')
          .select(
            'id, booking_code, user_id, counselor_id, slot_id, '
            'consultation_type, scheduled_start, scheduled_end, amount, '
            'notes, status, attendance_status, confirmed_at, '
            'attendance_confirmed_at, completed_at, cancelled_at, '
            'cancellation_reason, created_at, updated_at',
          )
          .eq('id', consultationId)
          .eq('user_id', user.id)
          .limit(1);

      final List<BookingModel> bookings =
          await _mergeBookings(consultationRows);

      if (bookings.isEmpty) {
        throw Exception('Booking tidak ditemukan.');
      }

      return bookings.first;
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> confirmOfflineAttendance(
    String consultationId,
  ) async {
    if (_client.auth.currentSession == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      await _client.rpc(
        'confirm_offline_attendance',
        params: <String, dynamic>{
          'p_consultation_id': consultationId,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<List<BookingModel>> _mergeBookings(
    List<dynamic> rawConsultations,
  ) async {
    if (rawConsultations.isEmpty) {
      return <BookingModel>[];
    }

    final List<Map<String, dynamic>> consultations = rawConsultations
        .map(
          (dynamic row) => Map<String, dynamic>.from(
            row as Map,
          ),
        )
        .toList();

    final List<String> consultationIds = consultations
        .map((Map<String, dynamic> row) => row['id']?.toString() ?? '')
        .where((String id) => id.isNotEmpty)
        .toList();

    final List<String> counselorIds = consultations
        .map(
          (Map<String, dynamic> row) =>
              row['counselor_id']?.toString() ?? '',
        )
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList();

    final List<dynamic> paymentRows = await _client
        .from('payments')
        .select(
          'id, consultation_id, user_id, method_id, amount, proof_path, '
          'status, submitted_at, verified_at, verified_by, '
          'rejection_reason, created_at, updated_at',
        )
        .inFilter('consultation_id', consultationIds);

    final List<dynamic> counselorProfileRows = counselorIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('profiles')
            .select('id, full_name, avatar_path, status')
            .inFilter('id', counselorIds);

    final List<dynamic> counselorDetailRows = counselorIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('counselor_profiles')
            .select('id, specialization, location')
            .inFilter('id', counselorIds);

    final List<dynamic> chatRoomRows = await _client
        .from('chat_rooms')
        .select('id, consultation_id')
        .inFilter('consultation_id', consultationIds);

    final Map<String, Map<String, dynamic>> paymentByConsultation =
        <String, Map<String, dynamic>>{};

    for (final dynamic rawPayment in paymentRows) {
      final Map<String, dynamic> payment =
          Map<String, dynamic>.from(rawPayment as Map);
      final String consultationId =
          payment['consultation_id']?.toString() ?? '';

      if (consultationId.isNotEmpty) {
        paymentByConsultation[consultationId] = payment;
      }
    }

    final Map<String, Map<String, dynamic>> profileById =
        <String, Map<String, dynamic>>{};

    for (final dynamic rawProfile in counselorProfileRows) {
      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(rawProfile as Map);
      final String id = profile['id']?.toString() ?? '';

      if (id.isNotEmpty) {
        profileById[id] = profile;
      }
    }

    final Map<String, Map<String, dynamic>> detailById =
        <String, Map<String, dynamic>>{};

    for (final dynamic rawDetail in counselorDetailRows) {
      final Map<String, dynamic> detail =
          Map<String, dynamic>.from(rawDetail as Map);
      final String id = detail['id']?.toString() ?? '';

      if (id.isNotEmpty) {
        detailById[id] = detail;
      }
    }

    final Map<String, Map<String, dynamic>> chatRoomByConsultation =
        <String, Map<String, dynamic>>{};

    for (final dynamic rawRoom in chatRoomRows) {
      final Map<String, dynamic> room =
          Map<String, dynamic>.from(rawRoom as Map);
      final String consultationId =
          room['consultation_id']?.toString() ?? '';

      if (consultationId.isNotEmpty) {
        chatRoomByConsultation[consultationId] = room;
      }
    }

    return consultations.map(
      (Map<String, dynamic> consultation) {
        final String consultationId =
            consultation['id']?.toString() ?? '';
        final String counselorId =
            consultation['counselor_id']?.toString() ?? '';

        return BookingModel.fromMergedMaps(
          consultation: consultation,
          payment: paymentByConsultation[consultationId],
          counselorProfile: profileById[counselorId],
          counselorDetail: detailById[counselorId],
          chatRoom: chatRoomByConsultation[consultationId],
        );
      },
    ).toList();
  }

  String _translateError(PostgrestException error) {
    final String message =
        '${error.code ?? ''} '
        '${error.message} '
        '${error.details ?? ''}'
            .toLowerCase();

    if (message.contains(
          'konsultasi tidak ditemukan atau bukan milik user',
        ) ||
        message.contains(
          'consultation not found',
        )) {
      return 'Booking tidak ditemukan atau bukan milik akunmu.';
    }

    if (message.contains(
          'attendance hanya berlaku untuk konsultasi offline',
        ) ||
        message.contains(
          'attendance confirmation is only for offline consultation',
        )) {
      return 'Konfirmasi kehadiran hanya tersedia '
          'untuk konsultasi offline.';
    }

    if (message.contains(
      'attendance hanya dapat dikonfirmasi oleh user',
    )) {
      return 'Konfirmasi kehadiran hanya dapat dilakukan '
          'melalui akun user.';
    }

    if (message.contains(
          'konsultasi belum dikonfirmasi oleh admin',
        ) ||
        message.contains(
          'payment has not been approved',
        )) {
      return 'Pembayaran belum disetujui admin.';
    }

    if (message.contains(
      'pembayaran konsultasi belum lunas',
    )) {
      return 'Pembayaran konsultasi belum berstatus lunas.';
    }

    if (message.contains(
      'attendance baru dapat dikonfirmasi mulai h-1',
    )) {
      return 'Konfirmasi kehadiran baru dapat dilakukan '
          'mulai H-1 jadwal konsultasi.';
    }

    if (message.contains(
      'waktu konfirmasi attendance sudah ditutup',
    )) {
      return 'Waktu konfirmasi kehadiran sudah berakhir '
          'karena jadwal konsultasi telah dimulai.';
    }

    if (message.contains(
      'akun user tidak aktif',
    )) {
      return 'Akunmu sedang tidak aktif.';
    }

    if (message.contains(
      'status attendance tidak dapat dikonfirmasi',
    )) {
      return 'Status kehadiran ini tidak dapat dikonfirmasi.';
    }

    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Kamu tidak memiliki izin untuk mengakses booking ini.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat memproses booking.'
        : error.message.trim();
  }

  String _cleanError(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }
}
