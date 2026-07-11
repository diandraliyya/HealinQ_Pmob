import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard_model.dart';

class AdminDashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AdminDashboardModel> getOverview() async {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'Sesi admin tidak ditemukan. '
        'Silakan login kembali.',
      );
    }

    try {
      final dynamic response = await _client.rpc(
        'get_admin_dashboard_overview',
      );

      if (response is! Map) {
        throw Exception(
          'Format data dashboard tidak valid.',
        );
      }

      return AdminDashboardModel.fromMap(
        Map<String, dynamic>.from(
          response,
        ),
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    } catch (error) {
      throw Exception(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim(),
      );
    }
  }

  String _translateError(
    PostgrestException error,
  ) {
    final String message = '${error.code ?? ''} '
            '${error.message} '
            '${error.details ?? ''}'
        .toLowerCase();

    if (message.contains(
      'hanya admin aktif',
    )) {
      return 'Akun ini tidak memiliki akses '
          'ke Dashboard Admin.';
    }

    if (message.contains('42501') ||
        message.contains(
          'permission denied',
        ) ||
        message.contains(
          'row-level security',
        )) {
      return 'Kamu tidak memiliki izin '
          'untuk melihat Dashboard Admin.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal memuat Dashboard Admin.'
        : error.message.trim();
  }
}
