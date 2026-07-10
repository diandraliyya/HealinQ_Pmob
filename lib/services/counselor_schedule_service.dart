import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/counselor_schedule_item_model.dart';

class CounselorScheduleService {
  final SupabaseClient _client = Supabase.instance.client;

  User _requireUser() {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return user;
  }

  Future<CounselorScheduleData> getScheduleData() async {
    final User user = _requireUser();

    try {
      await _expireStaleBookingsQuietly();
      await _syncOfflineStatusesQuietly();

      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(
        await _client
            .from('profiles')
            .select('id, full_name, role, status')
            .eq('id', user.id)
            .single(),
      );

      if (profile['role']?.toString() != 'counselor') {
        throw Exception(
          'Halaman ini hanya dapat diakses oleh counselor.',
        );
      }

      final Map<String, dynamic> counselorProfile =
          Map<String, dynamic>.from(
        await _client
            .from('counselor_profiles')
            .select(
              'id, offers_online, offers_offline, is_available',
            )
            .eq('id', user.id)
            .single(),
      );

      final List<dynamic> slotRows = await _client
          .from('counselor_slots')
          .select(
            'id, counselor_id, consultation_type, '
            'start_at, end_at, status, created_at, updated_at',
          )
          .eq('counselor_id', user.id)
          .order('start_at', ascending: true);

      final List<dynamic> consultationRows = await _client
          .from('consultations')
          .select(
            'id, booking_code, user_id, counselor_id, slot_id, '
            'consultation_type, scheduled_start, scheduled_end, '
            'amount, notes, status, attendance_status, '
            'confirmed_at, attendance_confirmed_at, attendance_marked_at, '
            'attendance_marked_by, completed_at, cancelled_at, '
            'cancellation_reason, created_at, updated_at',
          )
          .eq('counselor_id', user.id)
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>>
          consultationBySlot =
          <String, Map<String, dynamic>>{};

      final List<String> consultationIds = <String>[];

      for (final dynamic raw in consultationRows) {
        final Map<String, dynamic> consultation =
            Map<String, dynamic>.from(raw as Map);

        final String id =
            consultation['id']?.toString() ?? '';
        final String slotId =
            consultation['slot_id']?.toString() ?? '';

        if (id.isNotEmpty) {
          consultationIds.add(id);
        }

        if (slotId.isNotEmpty) {
          // Query diurutkan terbaru lebih dahulu.
          // putIfAbsent mempertahankan consultation terbaru per slot.
          consultationBySlot.putIfAbsent(
            slotId,
            () => consultation,
          );
        }
      }

      final List<dynamic> paymentRows =
          consultationIds.isEmpty
              ? <dynamic>[]
              : await _client
                  .from('payments')
                  .select(
                    'id, consultation_id, amount, status, '
                    'submitted_at, verified_at, rejection_reason, '
                    'created_at, updated_at',
                  )
                  .inFilter(
                    'consultation_id',
                    consultationIds,
                  );

      final List<dynamic> clientRows =
          consultationIds.isEmpty
              ? <dynamic>[]
              : await _client.rpc(
                  'get_my_consultation_clients',
                  params: <String, dynamic>{
                    'p_consultation_ids':
                        consultationIds,
                  },
                );

      final Map<String, Map<String, dynamic>>
          paymentByConsultation =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in paymentRows) {
        final Map<String, dynamic> payment =
            Map<String, dynamic>.from(raw as Map);

        final String consultationId =
            payment['consultation_id']?.toString() ?? '';

        if (consultationId.isNotEmpty) {
          paymentByConsultation[consultationId] = payment;
        }
      }

      final Map<String, Map<String, dynamic>>
          clientByConsultation =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in clientRows) {
        final Map<String, dynamic> client =
            Map<String, dynamic>.from(raw as Map);

        final String consultationId =
            client['consultation_id']?.toString() ?? '';

        if (consultationId.isNotEmpty) {
          clientByConsultation[consultationId] = client;
        }
      }

      final List<CounselorScheduleItemModel> items =
          slotRows.map(
        (dynamic raw) {
          final Map<String, dynamic> slot =
              Map<String, dynamic>.from(raw as Map);

          final String slotId =
              slot['id']?.toString() ?? '';

          final Map<String, dynamic>? consultation =
              consultationBySlot[slotId];

          final String consultationId =
              consultation?['id']?.toString() ?? '';

          return CounselorScheduleItemModel.fromMergedMaps(
            slot: slot,
            consultation: consultation,
            payment: paymentByConsultation[consultationId],
            clientProfile:
                clientByConsultation[consultationId],
          );
        },
      ).toList();

      return CounselorScheduleData(
        counselorName:
            profile['full_name']?.toString().trim().isNotEmpty ==
                    true
                ? profile['full_name'].toString().trim()
                : 'Counselor',
        accountStatus:
            profile['status']?.toString() ?? '',
        offersOnline:
            counselorProfile['offers_online'] == true,
        offersOffline:
            counselorProfile['offers_offline'] == true,
        items: items,
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> createSlot({
    required String consultationType,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final User user = _requireUser();

    try {
      await _client.from('counselor_slots').insert(
        <String, dynamic>{
          'counselor_id': user.id,
          'consultation_type': consultationType,
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt.toUtc().toIso8601String(),
          'status': 'available',
        },
      );

      await syncAvailability();
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> updateSlot({
    required String slotId,
    required String consultationType,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final User user = _requireUser();

    try {
      final List<dynamic> rows = await _client
          .from('counselor_slots')
          .update(
            <String, dynamic>{
              'consultation_type': consultationType,
              'start_at': startAt.toUtc().toIso8601String(),
              'end_at': endAt.toUtc().toIso8601String(),
              'updated_at':
                  DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq('id', slotId)
          .eq('counselor_id', user.id)
          .eq('status', 'available')
          .select('id');

      if (rows.isEmpty) {
        throw Exception(
          'Slot sudah berubah atau tidak lagi tersedia untuk diedit.',
        );
      }

      await syncAvailability();
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<String> deleteSlot(String slotId) async {
    _requireUser();

    try {
      final dynamic result = await _client.rpc(
        'remove_counselor_slot',
        params: <String, dynamic>{'p_slot_id': slotId},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(result as Map);
      await syncAvailability();
      return data['action']?.toString() ?? 'deleted';
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> markOfflineAttendance({
    required String consultationId,
    required String result,
  }) async {
    _requireUser();

    if (result != 'attended' && result != 'absent') {
      throw Exception('Hasil attendance tidak valid.');
    }

    try {
      await _client.rpc(
        'mark_offline_attendance',
        params: <String, dynamic>{
          'p_consultation_id': consultationId,
          'p_result': result,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> syncAvailability() async {
    final User user = _requireUser();

    try {
      final List<dynamic> availableRows = await _client
          .from('counselor_slots')
          .select('id')
          .eq('counselor_id', user.id)
          .eq('status', 'available')
          .gt(
            'start_at',
            DateTime.now().toUtc().toIso8601String(),
          )
          .limit(1);

      await _client
          .from('counselor_profiles')
          .update(
            <String, dynamic>{
              'is_available': availableRows.isNotEmpty,
            },
          )
          .eq('id', user.id);
    } on PostgrestException {
      // Indikator availability bersifat turunan dari slot.
      // Kegagalan sinkronisasi tidak membatalkan perubahan slot.
    }
  }

  Future<void> _syncOfflineStatusesQuietly() async {
    try {
      await _client.rpc('sync_offline_consultation_statuses');
    } catch (_) {
      // pg_cron tetap menjadi jalur utama.
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
        '${error.code ?? ''} '
        '${error.message} '
        '${error.details ?? ''}'
            .toLowerCase();

    if (message.contains('23p01') ||
        message.contains('counselor_slots_no_overlap') ||
        message.contains(
          'conflicting key value violates exclusion',
        )) {
      return 'Jadwal bertabrakan dengan slot lain yang '
          'sudah tersedia atau sudah dicadangkan.';
    }

    if (message.contains('mark attended baru aktif 30 menit sebelum jadwal')) {
      return 'Mark Attended baru aktif mulai 30 menit sebelum jadwal.';
    }

    if (message.contains('did not attend baru dapat dipilih setelah sesi selesai')) {
      return 'Did Not Attend baru dapat dipilih setelah jadwal konsultasi selesai.';
    }

    if (message.contains('attendance aktual sudah final')) {
      return 'Attendance aktual sudah dicatat dan tidak dapat diubah.';
    }

    if (message.contains('pembayaran konsultasi belum lunas')) {
      return 'Pembayaran konsultasi belum berstatus lunas.';
    }

    if (message.contains('konsultasi offline tidak dapat ditandai pada status ini')) {
      return 'Status konsultasi tidak dapat diubah untuk attendance saat ini.';
    }

    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Kamu tidak memiliki izin untuk mengakses '
          'atau mengubah jadwal ini.';
    }

    if (message.contains('end_at') &&
        message.contains('start_at')) {
      return 'Jam selesai harus lebih lambat dari jam mulai.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat mengelola jadwal.'
        : error.message.trim();
  }

  String _cleanError(String message) {
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst(
          'PostgrestException(message: ',
          '',
        )
        .trim();
  }
}
