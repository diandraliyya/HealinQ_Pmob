import 'dart:typed_data';

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
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'File bukti pembayaran kosong atau tidak dapat dibaca.',
      );
    }

    const int maximumFileSize = 2 * 1024 * 1024;

    if (bytes.length > maximumFileSize) {
      throw Exception(
        'Ukuran bukti pembayaran maksimal 2 MB.',
      );
    }

    final String extension = _resolveImageExtension(
      fileName: fileName,
      mimeType: mimeType,
    );

    final String contentType =
        _contentTypeForExtension(extension);

    final String path =
        '${user.id}/$paymentId/'
        '${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _client.storage
          .from('payment-proofs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );

      return path;
    } on StorageException catch (error) {
      throw Exception(error.message);
    }
  }

  String _resolveImageExtension({
    required String fileName,
    String? mimeType,
  }) {
    final String normalizedMimeType =
        mimeType?.trim().toLowerCase() ?? '';

    switch (normalizedMimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
    }

    final String normalizedFileName =
        fileName.trim().toLowerCase();

    if (normalizedFileName.contains('.')) {
      final String extension =
          normalizedFileName.split('.').last;

      if (<String>{
        'jpg',
        'jpeg',
        'png',
        'webp',
      }.contains(extension)) {
        return extension == 'jpeg' ? 'jpg' : extension;
      }
    }

    throw Exception(
      'Format bukti pembayaran harus JPG, JPEG, PNG, atau WEBP.',
    );
  }

  String _contentTypeForExtension(
    String extension,
  ) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      default:
        return 'image/jpeg';
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
