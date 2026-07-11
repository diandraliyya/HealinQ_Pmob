import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  static const int _maximumAvatarSizeBytes = 5 * 1024 * 1024;

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String username,
    required String email,
  }) async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final Map<String, dynamic> response =
        await _client
            .from('profiles')
            .update(<String, dynamic>{
              'full_name': fullName.trim(),
              'username': username.trim().toLowerCase(),
              'email': email.trim().toLowerCase(),
              'updated_at':
                  DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', user.id)
            .select()
            .single();

    return response;
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    if (bytes.isEmpty) {
      throw Exception('File foto kosong atau tidak dapat dibaca.');
    }

    if (bytes.length > _maximumAvatarSizeBytes) {
      throw Exception('Ukuran foto maksimal 5 MB.');
    }

    final String extension = _resolveExtension(
      fileName: fileName,
      mimeType: mimeType,
    );

    final String contentType = _contentTypeForExtension(extension);

    final Map<String, dynamic>? currentProfile =
        await _client
            .from('profiles')
            .select('avatar_path')
            .eq('id', user.id)
            .maybeSingle();

    final String? oldPath =
        currentProfile?['avatar_path']?.toString().trim();

    final String newPath =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _client.storage
          .from('profile-pictures')
          .uploadBinary(
            newPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );

      await _client
          .from('profiles')
          .update(<String, dynamic>{
            'avatar_path': newPath,
            'updated_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      if (oldPath != null &&
          oldPath.isNotEmpty &&
          oldPath != newPath &&
          !oldPath.startsWith('http://') &&
          !oldPath.startsWith('https://')) {
        try {
          await _client.storage
              .from('profile-pictures')
              .remove(<String>[oldPath]);
        } catch (_) {
          // Avatar baru tetap valid meskipun file lama gagal dibersihkan.
        }
      }

      return newPath;
    } catch (_) {
      try {
        await _client.storage
            .from('profile-pictures')
            .remove(<String>[newPath]);
      } catch (_) {
        // Abaikan kegagalan cleanup file upload yang belum terhubung ke profil.
      }

      rethrow;
    }
  }

  String getAvatarUrl(String? path) {
    final String normalizedPath = path?.trim() ?? '';

    if (normalizedPath.isEmpty) {
      return '';
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return normalizedPath;
    }

    return _client.storage
        .from('profile-pictures')
        .getPublicUrl(normalizedPath);
  }

  String _resolveExtension({
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
      final String candidate =
          normalizedFileName.split('.').last;

      if (<String>{'jpg', 'jpeg', 'png', 'webp'}
          .contains(candidate)) {
        return candidate == 'jpeg' ? 'jpg' : candidate;
      }
    }

    throw Exception(
      'Format foto harus JPG, JPEG, PNG, atau WEBP.',
    );
  }

  String _contentTypeForExtension(String extension) {
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
}
