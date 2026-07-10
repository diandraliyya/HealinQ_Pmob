import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_models.dart';

class ContentService {
  final SupabaseClient _client =
      Supabase.instance.client;

  User _requireUser() {
    final User? user =
        _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. '
        'Silakan login kembali.',
      );
    }

    return user;
  }

  Future<List<LyricContentModel>>
      getActiveLyrics() async {
    _requireUser();

    try {
      final List<dynamic> rows =
          await _client
              .from('lyrics')
              .select(
                'id, title, artist, lyric_excerpt, '
                'is_active, created_at, updated_at',
              )
              .eq('is_active', true)
              .order(
                'created_at',
                ascending: true,
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

  Future<LyricContentModel?>
      getLyricOfTheDay() async {
    final List<LyricContentModel> lyrics =
        await getActiveLyrics();

    if (lyrics.isEmpty) return null;

    final DateTime now = DateTime.now();

    final DateTime startOfYear =
        DateTime(now.year, 1, 1);

    final int dayOfYear = now
            .difference(startOfYear)
            .inDays +
        1;

    return lyrics[
        (dayOfYear - 1) % lyrics.length];
  }

  Future<List<JarItemContentModel>>
      getActiveJarItems() async {
    _requireUser();

    try {
      final List<dynamic> rows =
          await _client
              .from('jar_items')
              .select(
                'id, item_type, content, is_active, '
                'created_at, updated_at',
              )
              .eq('is_active', true)
              .order(
                'created_at',
                ascending: true,
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

  Future<List<PassionQuestionContentModel>>
      getActivePassionQuestions() async {
    _requireUser();

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
              .eq('is_active', true)
              .eq(
                'passion_categories.is_active',
                true,
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

  Future<List<PassionResultContentModel>>
      submitPassionTest(
    List<PassionQuestionContentModel>
        questions,
  ) async {
    _requireUser();

    if (questions.isEmpty) {
      throw Exception(
        'Pertanyaan FYP belum tersedia.',
      );
    }

    if (questions.any(
      (PassionQuestionContentModel question) =>
          question.answerValue == null,
    )) {
      throw Exception(
        'Semua pertanyaan harus dijawab.',
      );
    }

    final List<Map<String, dynamic>> answers =
        questions
            .map(
              (
                PassionQuestionContentModel
                    question,
              ) =>
                  <String, dynamic>{
                'question_id': question.id,
                'answer_value':
                    question.answerValue,
              },
            )
            .toList();

    try {
      final dynamic response =
          await _client.rpc(
        'submit_passion_test',
        params: <String, dynamic>{
          'p_answers': answers,
        },
      );

      final List<dynamic> rows =
          response is List<dynamic>
              ? response
              : <dynamic>[];

      return rows
          .map(
            (dynamic row) =>
                PassionResultContentModel
                    .fromMap(
              Map<String, dynamic>.from(
                row as Map,
              ),
            ),
          )
          .toList()
        ..sort(
          (
            PassionResultContentModel first,
            PassionResultContentModel second,
          ) =>
              first.resultRank.compareTo(
            second.resultRank,
          ),
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
      'every active question',
    )) {
      return 'Daftar pertanyaan berubah. '
          'Tekan refresh lalu isi kembali.';
    }

    if (combined.contains(
      'only active users',
    )) {
      return 'Hanya user aktif yang dapat '
          'mengisi Find Your Passion.';
    }

    if (combined.contains(
      'no active passion questions',
    )) {
      return 'Belum ada pertanyaan FYP aktif.';
    }

    if (combined.contains('42501') ||
        combined.contains(
          'permission denied',
        ) ||
        combined.contains(
          'row-level security',
        )) {
      return 'Kamu tidak memiliki izin '
          'untuk mengakses konten ini.';
    }

    return error.message.trim().isEmpty
        ? 'Gagal memuat content.'
        : error.message.trim();
  }
}
