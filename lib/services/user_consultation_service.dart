import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation_slot_model.dart';
import '../models/user_counselor_model.dart';

class UserConsultationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<UserCounselorModel>> getCounselors({
    required bool offline,
  }) async {
    try {
      await _expireStaleBookingsQuietly();

      final String consultationType = offline ? 'offline' : 'online';
      final String now = DateTime.now().toUtc().toIso8601String();

      final List<dynamic> slotRows = await _client
          .from('counselor_slots')
          .select('counselor_id, start_at')
          .eq('consultation_type', consultationType)
          .eq('status', 'available')
          .gt('start_at', now)
          .order('start_at');

      if (slotRows.isEmpty) return <UserCounselorModel>[];

      final Set<String> counselorIds = <String>{};
      for (final dynamic rawRow in slotRows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(rawRow as Map);
        final String counselorId = row['counselor_id']?.toString() ?? '';
        if (counselorId.isNotEmpty) counselorIds.add(counselorId);
      }

      if (counselorIds.isEmpty) return <UserCounselorModel>[];

      final List<dynamic> profileRows = await _client
          .from('profiles')
          .select('id, full_name, username, email, avatar_path, role, status')
          .eq('role', 'counselor')
          .eq('status', 'active')
          .inFilter('id', counselorIds.toList());

      if (profileRows.isEmpty) return <UserCounselorModel>[];

      final List<String> activeIds = profileRows
          .map((dynamic row) => (row as Map)['id']?.toString() ?? '')
          .where((String id) => id.isNotEmpty)
          .toList();

      final List<dynamic> detailRows = await _client
          .from('counselor_profiles')
          .select(
            'id, specialization, years_experience, location, '
            'professional_bio, offers_online, offers_offline, '
            'price_online, price_offline, rating, rating_count, '
            'is_available, approved_at',
          )
          .inFilter('id', activeIds)
          .not('approved_at', 'is', null)
          .eq(offline ? 'offers_offline' : 'offers_online', true);

      final Map<String, Map<String, dynamic>> detailById =
          <String, Map<String, dynamic>>{};
      for (final dynamic rawDetail in detailRows) {
        final Map<String, dynamic> detail =
            Map<String, dynamic>.from(rawDetail as Map);
        final String id = detail['id']?.toString() ?? '';
        if (id.isNotEmpty) detailById[id] = detail;
      }

      final List<UserCounselorModel> result = <UserCounselorModel>[];
      for (final dynamic rawProfile in profileRows) {
        final Map<String, dynamic> profile =
            Map<String, dynamic>.from(rawProfile as Map);
        final String id = profile['id']?.toString() ?? '';
        final Map<String, dynamic>? detail = detailById[id];
        if (id.isEmpty || detail == null) continue;

        result.add(
          UserCounselorModel.fromMap(<String, dynamic>{
            'id': id,
            'name': profile['full_name'],
            'username': profile['username'],
            'email': profile['email'],
            'avatar_path': profile['avatar_path'],
            'specialization': detail['specialization'],
            'years_experience': detail['years_experience'],
            'location': detail['location'],
            'bio': detail['professional_bio'],
            'offers_online': detail['offers_online'],
            'offers_offline': detail['offers_offline'],
            'price_online': detail['price_online'],
            'price_offline': detail['price_offline'],
            'rating': detail['rating'],
            'total_reviews': detail['rating_count'],
            'is_available': true,
          }),
        );
      }

      result.sort((UserCounselorModel first, UserCounselorModel second) {
        return second.rating.compareTo(first.rating);
      });

      return result;
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<List<ConsultationSlotModel>> getAvailableSlots(
    String counselorId,
    bool offline,
  ) async {
    try {
      await _expireStaleBookingsQuietly();

      final List<dynamic> rows = await _client
          .from('counselor_slots')
          .select('id, start_at, end_at, consultation_type')
          .eq('counselor_id', counselorId)
          .eq('consultation_type', offline ? 'offline' : 'online')
          .eq('status', 'available')
          .gt('start_at', DateTime.now().toUtc().toIso8601String())
          .order('start_at');

      return rows
          .map((dynamic row) => ConsultationSlotModel.fromMap(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList();
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String slotId,
    String? notes,
  }) async {
    if (_client.auth.currentSession == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    try {
      await _expireStaleBookingsQuietly();

      final dynamic result = await _client.rpc(
        'create_consultation_booking',
        params: <String, dynamic>{
          'p_slot_id': slotId,
          'p_notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        },
      );

      return Map<String, dynamic>.from(result as Map);
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> _expireStaleBookingsQuietly() async {
    try {
      await _client.rpc(
        'expire_stale_consultation_bookings',
        params: <String, dynamic>{'p_limit': 200},
      );
    } catch (_) {
      // pg_cron tetap menjadi jalur utama jika tersedia.
    }
  }

  String _translateError(PostgrestException error) {
    final String message =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();

    if (message.contains('slot sudah tidak tersedia')) {
      return 'Slot baru saja dipesan user lain. Silakan pilih slot lain.';
    }
    if (message.contains('akun user tidak aktif')) {
      return 'Akunmu tidak aktif dan tidak dapat membuat booking.';
    }
    if (message.contains('counselor tidak aktif')) {
      return 'Counselor sedang tidak tersedia.';
    }
    if (message.contains('row-level security') ||
        message.contains('42501') ||
        message.contains('permission denied')) {
      return 'Kamu tidak memiliki izin untuk mengakses data konsultasi.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat memproses konsultasi.'
        : error.message.trim();
  }

  String _cleanError(String message) =>
      message.replaceFirst('Exception: ', '').trim();
}
