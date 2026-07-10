import 'package:supabase_flutter/supabase_flutter.dart';

class CounselorReviewService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<Map<String, dynamic>> submitReview({
    required String consultationId,
    required int rating,
    String? reviewText,
  }) async {
    if (_client.auth.currentSession == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    if (rating < 1 || rating > 5) {
      throw Exception(
        'Pilih rating antara 1 sampai 5 bintang.',
      );
    }

    final String cleanReview =
        reviewText?.trim() ?? '';

    if (cleanReview.length > 1000) {
      throw Exception(
        'Review maksimal 1000 karakter.',
      );
    }

    try {
      final dynamic result = await _client.rpc(
        'submit_counselor_review',
        params: <String, dynamic>{
          'p_consultation_id': consultationId,
          'p_rating': rating,
          'p_review_text':
              cleanReview.isEmpty ? null : cleanReview,
        },
      );

      return Map<String, dynamic>.from(
        result as Map,
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    } catch (error) {
      throw Exception(
        _cleanError(error.toString()),
      );
    }
  }

  String _translateError(
    PostgrestException error,
  ) {
    final String message =
        '${error.code ?? ''} ${error.message} '
        '${error.details ?? ''}'.toLowerCase();

    if (message.contains(
      'rating hanya dapat diberikan setelah konsultasi selesai',
    )) {
      return 'Rating baru dapat diberikan setelah sesi selesai.';
    }

    if (message.contains(
      'konsultasi ini sudah pernah diberi rating',
    ) ||
        message.contains(
          'duplicate key',
        )) {
      return 'Konsultasi ini sudah pernah diberi rating.';
    }

    if (message.contains(
      'rating offline hanya tersedia jika user benar-benar hadir',
    )) {
      return 'Konsultasi offline hanya dapat dinilai jika '
          'counselor mencatat kamu hadir.';
    }

    if (message.contains(
      'pembayaran konsultasi belum lunas',
    )) {
      return 'Pembayaran konsultasi belum berstatus lunas.';
    }

    if (message.contains(
      'konsultasi tidak ditemukan atau bukan milik user',
    )) {
      return 'Konsultasi tidak ditemukan atau bukan milik akunmu.';
    }

    if (message.contains(
      'hanya user aktif yang dapat memberikan rating',
    )) {
      return 'Hanya akun user aktif yang dapat memberikan rating.';
    }

    if (message.contains('42501') ||
        message.contains(
          'permission denied',
        ) ||
        message.contains(
          'row-level security',
        )) {
      return 'Kamu tidak memiliki izin untuk memberikan rating.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal mengirim rating counselor.'
        : error.message.trim();
  }

  String _cleanError(String message) {
    return message
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}
