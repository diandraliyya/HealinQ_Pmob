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

  Future<String> uploadPaymentProof({
    required String paymentId,
    required File file,
  }) async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      final String extension =
          file.path.split('.').last.toLowerCase();

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
          throw Exception(
            'Format bukti pembayaran tidak didukung.',
          );
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

  Future<void> submitPayment({
    required String consultationId,
    required String proofPath,
    required String methodId,
  }) async {
    if (_client.auth.currentSession == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      await _client.rpc(
        'submit_payment_proof',
        params: <String, dynamic>{
          'p_consultation_id': consultationId,
          'p_method_id': methodId,
          'p_proof_path': proofPath,
        },
      );
    } on PostgrestException catch (error) {
      final String message =
          '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
              .toLowerCase();

      if (message.contains('payment cannot be submitted')) {
        throw Exception(
          'Pembayaran ini tidak dapat dikirim. '
          'Statusnya mungkin sudah berubah.',
        );
      }

      if (message.contains('payment method is not active')) {
        throw Exception(
          'Metode pembayaran sudah tidak aktif.',
        );
      }

      if (message.contains('invalid payment proof path')) {
        throw Exception(
          'Path bukti pembayaran tidak valid.',
        );
      }

      if (message.contains('42501') ||
          message.contains('permission denied') ||
          message.contains('row-level security')) {
        throw Exception(
          'Kamu tidak memiliki izin untuk mengirim bukti pembayaran.',
        );
      }

      throw Exception(
        error.message.trim().isEmpty
            ? 'Gagal mengirim bukti pembayaran.'
            : error.message.trim(),
      );
    }
  }

  Future<Map<String, dynamic>> getPaymentDetail(
    String paymentId,
  ) async {
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
      throw Exception(error.message);
    }
  }
}
