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

    // Apabila email confirmation dimatikan, signup otomatis membuat session.
    // Karena alur aplikasi ingin kembali ke login, session tersebut dikeluarkan.
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
          points,
          level,
          streak,
          created_at
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
          points,
          level,
          streak,
          created_at
        ''')
        .eq('id', user.id)
        .maybeSingle();

    return profile;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}