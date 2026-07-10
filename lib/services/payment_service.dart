import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _client
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<void> ensurePaymentCanBeSubmitted(String consultationId) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    await _expireStaleBookingsQuietly();

    final List<dynamic> consultations = await _client
        .from('consultations')
        .select('id, status')
        .eq('id', consultationId)
        .eq('user_id', user.id)
        .limit(1);

    if (consultations.isEmpty) {
      throw Exception('Booking tidak ditemukan.');
    }

    final List<dynamic> payments = await _client
        .from('payments')
        .select('id, status')
        .eq('consultation_id', consultationId)
        .eq('user_id', user.id)
        .limit(1);

    if (payments.isEmpty) {
      throw Exception('Data pembayaran tidak ditemukan.');
    }

    final String consultationStatus =
        (consultations.first as Map)['status']?.toString() ?? '';
    final String paymentStatus =
        (payments.first as Map)['status']?.toString() ?? '';

    if (consultationStatus == 'expired' || paymentStatus == 'expired') {
      throw Exception(
        'Batas pembayaran telah berakhir. Silakan pilih slot baru.',
      );
    }

    if (consultationStatus != 'pending_payment' ||
        (paymentStatus != 'unpaid' && paymentStatus != 'rejected')) {
      throw Exception(
        'Pembayaran ini tidak dapat dikirim karena statusnya sudah berubah.',
      );
    }
  }

  Future<String> uploadPaymentProof({
    required String paymentId,
    required File file,
  }) async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    try {
      final String extension = file.path.split('.').last.toLowerCase();
      final String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          throw Exception('Format bukti pembayaran tidak didukung.');
      }

      final String path =
          '${user.id}/$paymentId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _client.storage.from('payment-proofs').upload(
            path,
            file,
            fileOptions: FileOptions(
              upsert: false,
              contentType: contentType,
            ),
          );
      return path;
    } on StorageException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<void> deletePaymentProofQuietly(String proofPath) async {
    try {
      await _client.storage.from('payment-proofs').remove(<String>[proofPath]);
    } catch (_) {}
  }

  Future<void> submitPayment({
    required String consultationId,
    required String proofPath,
    required String methodId,
  }) async {
    if (_client.auth.currentSession == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    try {
      await ensurePaymentCanBeSubmitted(consultationId);
      await _client.rpc(
        'submit_payment_proof',
        params: <String, dynamic>{
          'p_consultation_id': consultationId,
          'p_method_id': methodId,
          'p_proof_path': proofPath,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    }
  }

  Future<Map<String, dynamic>> getPaymentDetail(String paymentId) async {
    try {
      final response = await _client
          .from('payments')
          .select('''
                *,
                payment_methods(
                  name,
                  method_type,
                  account_number,
                  account_name,
                  qr_image_path,
                  instructions
                )
              ''')
          .eq('id', paymentId)
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    }
  }

  Future<void> _expireStaleBookingsQuietly() async {
    try {
      await _client.rpc(
        'expire_stale_consultation_bookings',
        params: <String, dynamic>{'p_limit': 200},
      );
    } catch (_) {}
  }

  String _translateError(PostgrestException error) {
    final String message =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();

    if (message.contains('payment window expired')) {
      return 'Batas pembayaran 30 menit telah berakhir. Silakan pilih slot baru.';
    }
    if (message.contains('payment cannot be submitted')) {
      return 'Pembayaran tidak dapat dikirim. Status booking mungkin berubah atau kedaluwarsa.';
    }
    if (message.contains('payment method is not active')) {
      return 'Metode pembayaran sudah tidak aktif.';
    }
    if (message.contains('invalid payment proof path')) {
      return 'Path bukti pembayaran tidak valid.';
    }
    if (message.contains('akun user tidak aktif')) {
      return 'Akunmu sedang tidak aktif.';
    }
    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Kamu tidak memiliki izin untuk mengirim bukti pembayaran.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal memproses pembayaran.'
        : error.message.trim();
  }
}
