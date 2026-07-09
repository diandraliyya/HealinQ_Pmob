import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUpUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Gagal membuat akun.');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': username,
      'name': username,
      'email': email,
      'account_type': 'user',
    });

    return response;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Login gagal. User tidak ditemukan.');
    }

    final profile = await getCurrentProfile();

    if (profile == null) {
      throw Exception('Profile tidak ditemukan.');
    }

    return profile;
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    return profile;
  }

  String getCurrentUserRole(Map<String, dynamic> profile) {
    return profile['account_type'] as String? ?? 'user';
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
