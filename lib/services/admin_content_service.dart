import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_models.dart';

class AdminContentService {
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

  Future<List<LyricContentModel>>
      getAllLyrics() async {
    _requireAdminSession();

    try {
      final List<dynamic> rows =
          await _client
              .from('lyrics')
              .select(
                'id, title, artist, lyric_excerpt, '
                'is_active, created_at, updated_at',
              )
              .order(
                'created_at',
                ascending: false,
              );

      return rows
          .map(
            (dynamic row) =>
                LyricContentModel.fromMap(
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

  Future<List<JarItemContentModel>>
      getAllJarItems() async {
    _requireAdminSession();

    try {
      final List<dynamic> rows =
          await _client
              .from('jar_items')
              .select(
                'id, item_type, content, is_active, '
                'created_at, updated_at',
              )
              .order(
                'created_at',
                ascending: false,
              );

      return rows
          .map(
            (dynamic row) =>
                JarItemContentModel.fromMap(
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

  Future<List<PassionCategoryContentModel>>
      getCategories() async {
    _requireAdminSession();

    try {
      final List<dynamic> rows =
          await _client
              .from('passion_categories')
              .select(
                'id, code, name, emoji, description, is_active',
              )
              .order('name');

      return rows
          .map(
            (dynamic row) =>
                PassionCategoryContentModel
                    .fromMap(
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

  Future<List<PassionQuestionContentModel>>
      getAllPassionQuestions() async {
    _requireAdminSession();

    try {
      final List<dynamic> rows =
          await _client
              .from('passion_questions')
              .select(
                'id, category_id, question_text, '
                'is_active, sort_order, created_at, updated_at, '
                'passion_categories!inner('
                'id, code, name, emoji, is_active'
                ')',
              )
              .order(
                'sort_order',
                ascending: true,
              );

      return rows
          .map(
            (dynamic row) =>
                PassionQuestionContentModel.fromMap(
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

  Future<void> saveLyric({
    String? id,
    required String title,
    required String artist,
    required String lyricExcerpt,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_save_lyric',
        params: <String, dynamic>{
          'p_id': id,
          'p_title': title.trim(),
          'p_artist': artist.trim(),
          'p_lyric_excerpt':
              lyricExcerpt.trim(),
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> setLyricActive({
    required String id,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_set_lyric_active',
        params: <String, dynamic>{
          'p_id': id,
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> saveJarItem({
    String? id,
    required String itemType,
    required String content,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_save_jar_item',
        params: <String, dynamic>{
          'p_id': id,
          'p_item_type': itemType,
          'p_content': content.trim(),
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> setJarItemActive({
    required String id,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_set_jar_item_active',
        params: <String, dynamic>{
          'p_id': id,
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> savePassionQuestion({
    String? id,
    required String categoryCode,
    required String questionText,
    required int sortOrder,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_save_passion_question',
        params: <String, dynamic>{
          'p_id': id,
          'p_category_code': categoryCode,
          'p_question_text':
              questionText.trim(),
          'p_sort_order': sortOrder,
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateError(error),
      );
    }
  }

  Future<void> setPassionQuestionActive({
    required String id,
    required bool isActive,
  }) async {
    _requireAdminSession();

    try {
      await _client.rpc(
        'admin_set_passion_question_active',
        params: <String, dynamic>{
          'p_id': id,
          'p_is_active': isActive,
        },
      );
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

    if (combined.contains(
      'hanya admin aktif',
    )) {
      return 'Akun ini tidak memiliki akses '
          'ke Content Management.';
    }

    if (combined.contains('42501') ||
        combined.contains(
          'permission denied',
        ) ||
        combined.contains(
          'row-level security',
        )) {
      return 'Kamu tidak memiliki izin '
          'untuk mengelola content.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal mengelola content.'
        : error.message.trim();
  }
}
