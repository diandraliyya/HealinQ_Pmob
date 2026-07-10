import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user_model.dart';

class AdminUserService {
  final SupabaseClient _client =
      Supabase.instance.client;

  User _requireAdminSession() {
    final User? user =
        _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi admin tidak ditemukan. '
        'Silakan login kembali.',
      );
    }

    return user;
  }

  Future<List<AdminUserModel>>
      getAllUsers() async {
    _requireAdminSession();

    try {
      final dynamic response =
          await _client.rpc(
        'get_admin_users',
      );

      final List<dynamic> rows =
          response is List<dynamic>
              ? response
              : <dynamic>[];

      return rows
          .map(
            (dynamic row) =>
                AdminUserModel.fromMap(
              Map<String, dynamic>.from(
                row as Map,
              ),
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<String> setUserStatus({
    required String userId,
    required String status,
  }) async {
    _requireAdminSession();

    if (!<String>{
      'active',
      'inactive',
      'suspended',
    }.contains(status)) {
      throw Exception(
        'Status user tidak valid.',
      );
    }

    try {
      final dynamic response =
          await _client.rpc(
        'set_user_status',
        params: <String, dynamic>{
          'p_user_id': userId,
          'p_status': status,
        },
      );

      if (response is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(
          response,
        );

        return data['message']?.toString() ??
            'Status user berhasil diperbarui.';
      }

      return 'Status user berhasil diperbarui.';
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  String buildAvatarUrl(
    String? avatarPath,
  ) {
    if (avatarPath == null ||
        avatarPath.trim().isEmpty) {
      return '';
    }

    return _client.storage
        .from('profile-pictures')
        .getPublicUrl(
          avatarPath.trim(),
        );
  }

  String _translateError(
    PostgrestException error,
  ) {
    final String message =
        '${error.code ?? ''} '
        '${error.message} '
        '${error.details ?? ''}'
            .toLowerCase();

    if (message.contains(
      'hanya admin aktif',
    )) {
      return 'Akun ini tidak memiliki akses '
          'ke User Management.';
    }

    if (message.contains(
      'user tidak ditemukan',
    )) {
      return 'User tidak ditemukan.';
    }

    if (message.contains('42501') ||
        message.contains(
          'permission denied',
        ) ||
        message.contains(
          'row-level security',
        )) {
      return 'Kamu tidak memiliki izin '
          'untuk mengelola user.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan pada User Management.'
        : error.message.trim();
  }
}
