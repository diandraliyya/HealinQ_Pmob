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

      return List<Map<String, dynamic>>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    }
  }

  Future<String> uploadPaymentProof({
    required String paymentId,
    required File file,
  }) async {
    try {
      final String userId = _client.auth.currentUser!.id;

      final String extension = file.path.split('.').last;

      final String path = '$userId/$paymentId.$extension';

      await _client.storage.from('payment-proofs').upload(
            path,
            file,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      return path;
    } on StorageException catch (e) {
      throw Exception(
        e.message,
      );
    }
  }

  Future<void> submitPayment({
    required String paymentId,
    required String proofPath,
    required String methodId,
  }) async {
    try {
      await _client.from('payments').update({
        'method_id': methodId,
        'proof_path': proofPath,
        'status': 'pending_verification',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq(
        'id',
        paymentId,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
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
          .eq(
            'id',
            paymentId,
          )
          .single();

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        e.message,
      );
    }
  }
}
