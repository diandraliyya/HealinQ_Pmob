import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/content_models.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class FypScreen extends StatefulWidget {
  const FypScreen({super.key});

  @override
  State<FypScreen> createState() =>
      _FypScreenState();
}

class _FypScreenState
    extends State<FypScreen> {
  final ContentService _service =
      ContentService();

  final PageController _lyricController =
      PageController(
    viewportFraction: 0.96,
  );

  List<LyricContentModel> _lyrics =
      <LyricContentModel>[];

  List<PassionQuestionContentModel>
      _questions =
      <PassionQuestionContentModel>[];

  List<PassionResultContentModel>
      _results =
      <PassionResultContentModel>[];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;

  int _currentLyricIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _lyricController.dispose();
    super.dispose();
  }

  Future<void> _loadContent({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<dynamic> result =
          await Future.wait<dynamic>(
        <Future<dynamic>>[
          _service.getActiveLyrics(),
          _service
              .getActivePassionQuestions(),
        ],
      );

      final List<LyricContentModel> lyrics =
          result[0]
              as List<LyricContentModel>;

      final List<
              PassionQuestionContentModel>
          questions = result[1]
              as List<
                  PassionQuestionContentModel>;

      for (final PassionQuestionContentModel
          question in questions) {
        question.answerValue = null;
      }

      final int dailyIndex =
          _dailyLyricIndex(lyrics);

      if (!mounted) return;

      setState(() {
        _lyrics = lyrics;
        _questions = questions;
        _results =
            <PassionResultContentModel>[];
        _submitted = false;
        _currentLyricIndex =
            dailyIndex;
        _errorMessage = null;
      });

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (_lyricController.hasClients &&
              _lyrics.isNotEmpty) {
            _lyricController.jumpToPage(
              dailyIndex,
            );
          }
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanError(
          error,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _dailyLyricIndex(
    List<LyricContentModel> lyrics,
  ) {
    if (lyrics.isEmpty) return 0;

    final DateTime now = DateTime.now();

    final DateTime startOfYear =
        DateTime(now.year, 1, 1);

    final int dayOfYear = now
            .difference(startOfYear)
            .inDays +
        1;

    return (dayOfYear - 1) %
        lyrics.length;
  }

  void _resetAnswers() {
    setState(() {
      for (final PassionQuestionContentModel
          question in _questions) {
        question.answerValue = null;
      }

      _results =
          <PassionResultContentModel>[];
      _submitted = false;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_questions.isEmpty) {
      _showMessage(
        'Belum ada pertanyaan FYP aktif.',
        isError: true,
      );
      return;
    }

    if (_questions.any(
      (
        PassionQuestionContentModel
            question,
      ) =>
          question.answerValue == null,
    )) {
      _showMessage(
        'Please answer all questions!',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final List<
              PassionResultContentModel>
          result =
          await _service.submitPassionTest(
        _questions,
      );

      if (!mounted) return;

      setState(() {
        _results = result
            .take(3)
            .toList();
        _submitted = true;
      });

      _showMessage(
        'Hasil Find Your Passion berhasil disimpan.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.success,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFB2EBF2),
            Color(0xFFFCE4EC),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'FYP',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                        color: AppColors
                            .primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Refresh Content',
                    onPressed: _isLoading
                        ? null
                        : _loadContent,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color:
                          AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 100),
          Container(
            padding:
                const EdgeInsets.all(
              24,
            ),
            decoration: BoxDecoration(
              color: AppColors.white
                  .withOpacity(0.94),
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons
                      .error_outline_rounded,
                  size: 50,
                  color: AppColors.error,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  _errorMessage!,
                  textAlign:
                      TextAlign.center,
                  style:
                      GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors
                        .textMedium,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                ElevatedButton.icon(
                  onPressed:
                      _loadContent,
                  icon: const Icon(
                    Icons
                        .refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () {
        return _loadContent(
          showLoading: false,
        );
      },
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24,
        ),
        child: Column(
          children: <Widget>[
            _buildLyricSection(),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: <Widget>[
                      Text(
                        'Find Your Passion',
                        style: GoogleFonts
                            .poppins(
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color: AppColors
                              .primary,
                        ),
                      ),
                      Text(
                        '${_questions.length} active questions',
                        style: GoogleFonts
                            .poppins(
                          fontSize: 11,
                          color: AppColors
                              .textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      'Reset answers',
                  onPressed:
                      _resetAnswers,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    color:
                        AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_questions.isEmpty)
              _buildEmptyQuestions()
            else
              ..._questions.map(
                _buildQuestion,
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : _submit,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      AppColors.teal,
                  foregroundColor:
                      AppColors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              AppColors.white,
                        ),
                      )
                    : Text(
                        'SUBMIT',
                        style: GoogleFonts
                            .poppins(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricSection() {
    if (_lyrics.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white
              .withOpacity(0.9),
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Text(
          'Belum ada Lyric of the Day aktif.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color:
                AppColors.textMedium,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller:
                _lyricController,
            itemCount: _lyrics.length,
            onPageChanged: (
              int index,
            ) {
              setState(() {
                _currentLyricIndex =
                    index;
              });
            },
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              return Padding(
                padding:
                    const EdgeInsets
                        .only(
                  right: 6,
                ),
                child:
                    _buildLyricCard(
                  _lyrics[index],
                  index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: List<Widget>.generate(
            _lyrics.length,
            (int index) =>
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
              margin:
                  const EdgeInsets
                      .symmetric(
                horizontal: 3,
              ),
              width:
                  _currentLyricIndex ==
                          index
                      ? 18
                      : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    _currentLyricIndex ==
                            index
                        ? AppColors
                            .primary
                        : AppColors.white
                            .withOpacity(
                            0.7,
                          ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricCard(
    LyricContentModel lyric,
    int index,
  ) {
    final bool isToday =
        index ==
            _dailyLyricIndex(
              _lyrics,
            );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.9),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.music_note_rounded,
                color:
                    AppColors.primary,
                size: 18,
              ),
              Text(
                ' Lyric Of The Day',
                style:
                    GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors
                        .primarySoft,
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts
                        .poppins(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                      color: AppColors
                          .primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lyric.title,
            style:
                GoogleFonts.poppins(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            lyric.artist,
            style:
                GoogleFonts.poppins(
              fontSize: 11,
              color:
                  AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              lyric.lyricExcerpt,
              style:
                  GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors
                    .textMedium,
                fontStyle:
                    FontStyle.italic,
                height: 1.55,
              ),
              maxLines: 5,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    PassionQuestionContentModel
        question,
  ) {
    const List<String> labels =
        <String>[
      'Tidak\nSesuai',
      'Kurang',
      'Netral',
      'Sesuai',
      'Sangat\nSesuai',
    ];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.9),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors
                      .primarySoft,
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child: Text(
                  '${question.categoryEmoji} '
                  '${question.categoryName}',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w600,
                    color: AppColors
                        .primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${question.sortOrder}',
                style:
                    GoogleFonts.poppins(
                  fontSize: 9,
                  color: AppColors
                      .textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.questionText,
            style:
                GoogleFonts.poppins(
              fontSize: 13,
              color:
                  AppColors.textDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceAround,
            children:
                List<Widget>.generate(
              5,
              (int index) =>
                  GestureDetector(
                onTap: () {
                  setState(() {
                    question.answerValue =
                        index + 1;
                    _submitted = false;
                    _results = <
                        PassionResultContentModel>[];
                  });
                },
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color: question
                                    .answerValue ==
                                index + 1
                            ? AppColors
                                .primary
                            : Colors
                                .transparent,
                        border:
                            Border.all(
                          color: question
                                      .answerValue ==
                                  index + 1
                              ? AppColors
                                  .primary
                              : Colors.grey
                                  .shade300,
                          width: 1.5,
                        ),
                      ),
                      child: question
                                  .answerValue ==
                              index + 1
                          ? const Icon(
                              Icons.check,
                              color: AppColors
                                  .white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      labels[index],
                      style: GoogleFonts
                          .poppins(
                        fontSize: 8,
                        color: AppColors
                            .textLight,
                      ),
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestions() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.9),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.psychology_outlined,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada pertanyaan aktif',
            style:
                GoogleFonts.poppins(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Admin perlu mengaktifkan pertanyaan FYP terlebih dahulu.',
            textAlign:
                TextAlign.center,
            style:
                GoogleFonts.poppins(
              fontSize: 11,
              color:
                  AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: <Color>[
            Color(0xFFF8BBD9),
            Color(0xFFE0F7FA),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Your Match Results',
            style:
                GoogleFonts.poppins(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          if (!_submitted)
            Text(
              'Answer all active questions and submit to see your passion matches!',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors
                    .textMedium,
              ),
            )
          else if (_results.isEmpty)
            Text(
              'Hasil belum tersedia.',
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors
                    .textMedium,
              ),
            )
          else ...<Widget>[
            Text(
              'Your top passion areas are:',
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors
                    .textMedium,
              ),
            ),
            const SizedBox(height: 12),
            ..._results.asMap().entries.map(
              (
                MapEntry<
                        int,
                        PassionResultContentModel>
                    entry,
              ) {
                final PassionResultContentModel
                    result =
                    entry.value;

                return Container(
                  margin:
                      const EdgeInsets
                          .only(
                    bottom: 10,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color: AppColors.white
                        .withOpacity(
                      0.8,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    border: Border.all(
                      color: AppColors
                          .primary
                          .withOpacity(
                        0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            AppColors
                                .primary,
                        child: Text(
                          '${entry.key + 1}',
                          style: GoogleFonts
                              .poppins(
                            color: AppColors
                                .white,
                            fontWeight:
                                FontWeight
                                    .w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 11,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: <Widget>[
                            Text(
                              result
                                  .displayLabel,
                              style:
                                  GoogleFonts
                                      .poppins(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color: AppColors
                                    .textDark,
                              ),
                            ),
                            Text(
                              '${result.normalizedScore.toStringAsFixed(1)}%',
                              style:
                                  GoogleFonts
                                      .poppins(
                                fontSize: 11,
                                color: AppColors
                                    .primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
