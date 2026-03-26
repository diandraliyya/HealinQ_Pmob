import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_data.dart';
import '../../utils/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class FypScreen extends StatefulWidget {
  const FypScreen({super.key});

  @override
  State<FypScreen> createState() => _FypScreenState();
}

class _FypScreenState extends State<FypScreen> {
  static const int _questionCountPerRound = 8;

  final PageController _lyricController =
      PageController(viewportFraction: 0.96);

  List<PassionQuestion> _questions = [];
  bool _submitted = false;
  List<String> _results = [];
  int _currentLyricIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetQuestions();
    _setDailyLyricPage();
  }

  @override
  void dispose() {
    _lyricController.dispose();
    super.dispose();
  }

  void _setDailyLyricPage() {
    final dailyIndex = _getDailyLyricIndex();
    _currentLyricIndex = dailyIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lyricController.hasClients) {
        _lyricController.jumpToPage(dailyIndex);
      }
    });
  }

  int _getDailyLyricIndex() {
    final now = DateTime.now();
    return (now.year + now.month + now.day) % AppData.lyrics.length;
  }

  void _resetQuestions() {
    final shuffled = List<PassionQuestion>.from(AppData.passionQuestions);
    shuffled.shuffle(Random());

    final selected = shuffled.take(_questionCountPerRound).map((q) {
      return PassionQuestion(
        id: q.id,
        questionText: q.questionText,
      );
    }).toList();

    setState(() {
      _questions = selected;
      _submitted = false;
      _results = [];
    });
  }

  void _submit() {
    if (_questions.any((q) => q.answerValue == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    int techScore = 0;
    int artScore = 0;
    int socialScore = 0;
    int sportScore = 0;
    int businessScore = 0;
    int educationScore = 0;

    for (final q in _questions) {
      final score = q.answerValue ?? 0;
      final text = q.questionText.toLowerCase();

      if (text.contains('teka-teki') ||
          text.contains('masalah rumit') ||
          text.contains('teknologi') ||
          text.contains('penelitian') ||
          text.contains('eksperimen') ||
          text.contains('data')) {
        techScore += score;
      }

      if (text.contains('seni') ||
          text.contains('kreatif') ||
          text.contains('menulis cerita') ||
          text.contains('desain') ||
          text.contains('visual') ||
          text.contains('konten')) {
        artScore += score;
      }

      if (text.contains('membantu orang lain') ||
          text.contains('berinteraksi') ||
          text.contains('mendengarkan curhatan')) {
        socialScore += score;
      }

      if (text.contains('olahraga') || text.contains('aktivitas fisik')) {
        sportScore += score;
      }

      if (text.contains('bisnis') ||
          text.contains('berwirausaha') ||
          text.contains('mengelola') ||
          text.contains('mengorganisir') ||
          text.contains('memimpin') ||
          text.contains('strategi')) {
        businessScore += score;
      }

      if (text.contains('mengajar') ||
          text.contains('berbagi pengetahuan') ||
          text.contains('belajar hal-hal baru')) {
        educationScore += score;
      }
    }

    final scores = {
      'Technology 💻': techScore,
      'Art & Creative 🎨': artScore,
      'Social & Humanity 🤝': socialScore,
      'Sports & Health 🏃': sportScore,
      'Business 💼': businessScore,
      'Education 📚': educationScore,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _submitted = true;
      _results = sorted.take(3).map((e) => e.key).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB2EBF2), Color(0xFFFCE4EC)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FYP',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      ScoreCard(xp: state.currentUser?.point ?? 0),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildLyricSection(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Find Your Passion',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: _resetQuestions,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._questions.map((q) => _buildQuestion(q)),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'SUBMIT',
                      onPressed: _submit,
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 24),
                    _buildResultCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricSection() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _lyricController,
            itemCount: AppData.lyrics.length,
            onPageChanged: (index) {
              setState(() => _currentLyricIndex = index);
            },
            itemBuilder: (context, index) {
              final lyric = AppData.lyrics[index];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildLyricCard(lyric),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            AppData.lyrics.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentLyricIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentLyricIndex == index
                    ? AppColors.primary
                    : AppColors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricCard(Map<String, String> lyric) {
    final isToday = _currentLyricIndex == _getDailyLyricIndex();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              Text(
                ' Lyric Of The Day',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lyric['title'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lyric['artist'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lyric['lyric'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(PassionQuestion q) {
    final labels = ['Tidak\nPernah', 'Jarang', 'Kadang', 'Sering', 'Selalu'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.questionText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => q.answerValue = i + 1),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: q.answerValue == i + 1
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: q.answerValue == i + 1
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: q.answerValue == i + 1
                          ? const Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8BBD9), Color(0xFFE0F7FA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Your Match Results',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (!_submitted)
            Text(
              'Answer all questions and submit to see your passion matches!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            )
          else ...[
            Text(
              'Your top passion areas are:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            ..._results.asMap().entries.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: GoogleFonts.poppins(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            Text(
              'Keep exploring your passion! 🌟',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!_submitted) ...[
            const SizedBox(height: 12),
            _placeholderRow(3),
            const SizedBox(height: 8),
            _placeholderRow(3),
            const SizedBox(height: 8),
            _placeholderRow(2),
          ],
        ],
      ),
    );
  }

  Widget _placeholderRow(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 80,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
