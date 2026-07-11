import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String username,
    required String email,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'User belum login',
      );
    }

    final response = await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'username': username,
          'email': email,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id)
        .select()
        .single();

    return response;
  }

  Future<String> uploadAvatar({
    required File file,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'User belum login',
      );
    }

    final extension = file.path.split('.').last;

    final path = '${user.id}/avatar.$extension';

    await _client.storage.from('profile-pictures').upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    await _client.from('profiles').update({
      'avatar_path': path,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    return path;
  }

  String getAvatarUrl(
    String? path,
  ) {
    if (path == null || path.isEmpty) {
      return '';
    }

    return _client.storage.from('profile-pictures').getPublicUrl(path);
  }
}
