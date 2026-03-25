import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_data.dart';
import '../../utils/app_state.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'package:provider/provider.dart';

class FypScreen extends StatefulWidget {
  const FypScreen({super.key});

  @override
  State<FypScreen> createState() => _FypScreenState();
}

class _FypScreenState extends State<FypScreen> {
  List<PassionQuestion> _questions = [];
  bool _submitted = false;
  List<String> _results = [];

  @override
  void initState() {
    super.initState();
    _resetQuestions();
  }

  void _resetQuestions() {
    _questions = AppData.passionQuestions.map((q) => PassionQuestion(id: q.id, questionText: q.questionText)).toList();
    _submitted = false;
    _results = [];
  }

  void _submit() {
    if (_questions.any((q) => q.answerValue == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer all questions!'), backgroundColor: AppColors.error));
      return;
    }
    // Simple scoring logic
    final techScore = (_questions[0].answerValue ?? 0) + (_questions[3].answerValue ?? 0);
    final artScore = (_questions[1].answerValue ?? 0) + (_questions[6].answerValue ?? 0);
    final socialScore = (_questions[2].answerValue ?? 0) + (_questions[4].answerValue ?? 0);
    final sportScore = (_questions[5].answerValue ?? 0);
    final businessScore = (_questions[7].answerValue ?? 0) + (_questions[9].answerValue ?? 0);
    final educationScore = (_questions[10].answerValue ?? 0);

    final scores = {
      'Technology 💻': techScore, 'Art & Creative 🎨': artScore, 'Social & Humanity 🤝': socialScore,
      'Sports & Health 🏃': sportScore, 'Business 💼': businessScore, 'Education 📚': educationScore,
    };
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                  Text('FYP', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Row(children: [
                    ScoreCard(xp: state.currentUser?.point ?? 0),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Lyric of the Day
                    _buildLyricCard(),
                    const SizedBox(height: 20),
                    // Find Your Passion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Find Your Passion', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        IconButton(onPressed: () => setState(_resetQuestions), icon: const Icon(Icons.refresh_rounded, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Questions
                    ..._questions.asMap().entries.map((entry) => _buildQuestion(entry.value)),
                    const SizedBox(height: 20),
                    // Submit button
                    AppButton(text: 'SUBMIT', onPressed: _submit, color: AppColors.teal),
                    const SizedBox(height: 24),
                    // Results
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

  Widget _buildLyricCard() {
    final lyric = AppData.lyricOfTheDay;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 18),
            Text(' Lyric Of The Day', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          Text(lyric['title'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(lyric['lyric'] ?? '', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium, fontStyle: FontStyle.italic, height: 1.6)),
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
        color: AppColors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.questionText, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => q.answerValue = i + 1),
              child: Column(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: q.answerValue == i + 1 ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: q.answerValue == i + 1 ? AppColors.primary : Colors.grey.shade300, width: 1.5),
                    ),
                    child: q.answerValue == i + 1 ? const Icon(Icons.check, color: AppColors.white, size: 18) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i], style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight), textAlign: TextAlign.center),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF8BBD9), Color(0xFFE0F7FA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Your Match Results', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 16),
          if (!_submitted)
            Text('Answer all questions and submit to see your passion matches!', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium))
          else ...[
            Text('Your top passion areas are:', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
            const SizedBox(height: 12),
            ..._results.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}', style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Text('Keep exploring your passion! 🌟', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium, fontStyle: FontStyle.italic)),
          ],
          // Placeholder boxes for when not submitted
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
      children: List.generate(count, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 80, height: 28,
        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
      )),
    );
  }
}
