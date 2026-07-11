import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> signUpUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedRole = role == 'counselor' ? 'counselor' : 'user';

    final usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');

    if (!usernameRegex.hasMatch(normalizedUsername)) {
      throw Exception(
        'Username hanya boleh berisi huruf kecil, angka, dan underscore.',
      );
    }

    final available = await _supabase.rpc(
      'is_username_available',
      params: {
        'p_username': normalizedUsername,
      },
    );

    if (available != true) {
      throw Exception('Username sudah digunakan.');
    }

    final response = await _supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        'username': normalizedUsername,
        'full_name': fullName.trim(),
        'role': normalizedRole,
      },
    );

    if (response.user == null) {
      throw Exception('Akun gagal dibuat.');
    }

    final confirmationRequired = response.session == null;

    if (response.session != null) {
      await _supabase.auth.signOut();
    }

    return {
      'user_id': response.user!.id,
      'role': normalizedRole,
      'confirmation_required': confirmationRequired,
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Email atau password salah.');
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('''
            id,
            username,
            full_name,
            email,
            role,
            status,
            phone,
            address,
            avatar_path,
            bio,
            birth_date,
            gender,
            created_at,
            updated_at
          ''')
          .eq('id', user.id)
          .single();

      final status = profile['status'] as String?;
      final role = profile['role'] as String?;

      if (status == 'inactive') {
        await _supabase.auth.signOut();
        throw Exception('Akun kamu sedang tidak aktif.');
      }

      if (status == 'suspended') {
        await _supabase.auth.signOut();
        throw Exception('Akun kamu sedang ditangguhkan.');
      }

      if (role == null) {
        await _supabase.auth.signOut();
        throw Exception('Role akun tidak ditemukan.');
      }

      return profile;
    } catch (_) {
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.signOut();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _supabase
        .from('profiles')
        .select('''
          id,
          username,
          full_name,
          email,
          role,
          status,
          phone,
          address,
          avatar_path,
          bio,
          birth_date,
          gender,
          created_at,
          updated_at
        ''')
        .eq('id', user.id)
        .maybeSingle();

    return profile;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? currentUser =
        _supabase.auth.currentUser;

    final String? email =
        currentUser?.email?.trim().toLowerCase();

    if (currentUser == null ||
        email == null ||
        email.isEmpty) {
      throw Exception(
        'Sesi login atau email akun tidak ditemukan.',
      );
    }

    if (currentPassword.isEmpty) {
      throw Exception(
        'Password saat ini wajib diisi.',
      );
    }

    if (newPassword.length < 6) {
      throw Exception(
        'Password baru minimal 6 karakter.',
      );
    }

    if (currentPassword == newPassword) {
      throw Exception(
        'Password baru harus berbeda dari password lama.',
      );
    }

    final AuthResponse verificationResponse =
        await _supabase.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    if (verificationResponse.user == null ||
        verificationResponse.user!.id !=
            currentUser.id) {
      throw Exception(
        'Password saat ini tidak dapat diverifikasi.',
      );
    }

    await updatePassword(newPassword);
  }

  Future<void> updatePassword(
    String newPassword,
  ) async {
    final User? user =
        _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    await _supabase.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
}
