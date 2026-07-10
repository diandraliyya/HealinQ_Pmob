import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class JournalService {
  final SupabaseClient _client =
      Supabase.instance.client;

  User _requireUser() {
    final User? user =
        _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi user tidak ditemukan. Silakan login kembali.',
      );
    }

    return user;
  }

  Future<List<JournalModel>> getMyJournals() async {
    final User user = _requireUser();

    try {
      final List<dynamic> rows = await _client
          .from('journals')
          .select(
            'id, user_id, title, content, mood_tag, '
            'created_at, updated_at',
          )
          .eq('user_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      return rows
          .map(
            (dynamic row) => JournalModel.fromMap(
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

  Future<JournalModel> createJournal({
    required String title,
    required String content,
    required String moodTag,
  }) async {
    final User user = _requireUser();
    final String cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      throw Exception(
        'Isi jurnal tidak boleh kosong.',
      );
    }

    try {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(
        await _client
            .from('journals')
            .insert(<String, dynamic>{
              'user_id': user.id,
              'title': title.trim().isEmpty
                  ? null
                  : title.trim(),
              'content': cleanContent,
              'mood_tag': moodTag.trim().isEmpty
                  ? null
                  : moodTag.trim(),
            })
            .select(
              'id, user_id, title, content, mood_tag, '
              'created_at, updated_at',
            )
            .single(),
      );

      return JournalModel.fromMap(row);
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<JournalModel> updateJournal({
    required String journalId,
    required String title,
    required String content,
    required String moodTag,
  }) async {
    final User user = _requireUser();
    final String cleanContent = content.trim();

    if (journalId.trim().isEmpty) {
      throw Exception(
        'Journal tidak ditemukan.',
      );
    }

    if (cleanContent.isEmpty) {
      throw Exception(
        'Isi jurnal tidak boleh kosong.',
      );
    }

    try {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(
        await _client
            .from('journals')
            .update(<String, dynamic>{
              'title': title.trim().isEmpty
                  ? null
                  : title.trim(),
              'content': cleanContent,
              'mood_tag': moodTag.trim().isEmpty
                  ? null
                  : moodTag.trim(),
            })
            .eq('id', journalId)
            .eq('user_id', user.id)
            .select(
              'id, user_id, title, content, mood_tag, '
              'created_at, updated_at',
            )
            .single(),
      );

      return JournalModel.fromMap(row);
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> deleteJournal(
    String journalId,
  ) async {
    final User user = _requireUser();

    if (journalId.trim().isEmpty) {
      throw Exception(
        'Journal tidak ditemukan.',
      );
    }

    try {
      await _client
          .from('journals')
          .delete()
          .eq('id', journalId)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  String _translateError(
    PostgrestException error,
  ) {
    final String combined =
        '${error.code ?? ''} '
        '${error.message} '
        '${error.details ?? ''}'
            .toLowerCase();

    if (combined.contains('42501') ||
        combined.contains('row-level security') ||
        combined.contains('permission denied')) {
      return 'Akun ini tidak memiliki izin untuk mengelola jurnal.';
    }

    if (combined.contains('char_length') ||
        combined.contains('check constraint')) {
      return 'Isi jurnal tidak boleh kosong.';
    }

    if (combined.contains('pgrst116') ||
        combined.contains('multiple (or no) rows returned')) {
      return 'Journal tidak ditemukan atau tidak dapat diubah.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat memproses jurnal.'
        : error.message.trim();
  }
}
