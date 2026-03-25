import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../utils/app_data.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class SelfHealingScreen extends StatefulWidget {
  const SelfHealingScreen({super.key});

  @override
  State<SelfHealingScreen> createState() => _SelfHealingScreenState();
}

class _SelfHealingScreenState extends State<SelfHealingScreen> {
  String? _jarMessage;
  bool _showJarDialog = false;

  void _pickFromJar() {
    final random = Random();
    final item = AppData.jarItems[random.nextInt(AppData.jarItems.length)];
    setState(() => _jarMessage = item['content']);
    _showJarDialog = true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.pinkCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(item['content'] ?? '', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textDark, height: 1.5)),
          ],
        ),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Tutup', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final journals = state.journals;
    final todayJournals = journals.where((j) => DateFormat('yyyy-MM-dd').format(j.createdAt) == DateFormat('yyyy-MM-dd').format(DateTime.now())).toList();
    final lastWeekJournals = journals.where((j) => j.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 1)))).toList();

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
                  Text('Self Healing', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ScoreCard(xp: state.currentUser?.point ?? 0),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Jar of Happiness
                    _buildJarCard(),
                    const SizedBox(height: 20),
                    // Daily Journaling
                    _buildJournalingHeader(),
                    const SizedBox(height: 16),
                    // Today's journals
                    Text('Today', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    if (todayJournals.isEmpty)
                      _buildEmptyJournal()
                    else
                      ...todayJournals.map((j) => _buildJournalCard(j)),
                    const SizedBox(height: 16),
                    Text('Last Week', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...lastWeekJournals.take(4).map((j) => _buildJournalCard(j)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // FAB for new journal - handled outside
    );
  }

  Widget _buildJarCard() {
    return GestureDetector(
      onTap: _pickFromJar,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFFCE4EC)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text('Jar of Happiness', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text('Pick one to brighten up your day', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            SizedBox(height: 160, width: 160, child: CustomPaint(painter: _JarPainter())),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalingHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB2EBF2), Color(0xFFE0F7FA)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('Daily Journaling', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.teal)),
          Text('Where thought find their words', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEmptyJournal() {
    return GestureDetector(
      onTap: () => _showAddJournalDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight, style: BorderStyle.solid),
        ),
        child: Column(children: [
          const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 32),
          Text('Tap to write your first journal today!', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
        ]),
      ),
    );
  }

  Widget _buildJournalCard(JournalModel journal) {
    return GestureDetector(
      onTap: () => _showJournalDetail(context, journal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (journal.title.isNotEmpty)
              Text(journal.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(journal.content, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(DateFormat('EEEE, d MMM').format(journal.createdAt), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  void _showAddJournalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedMood = '😊';
    final moods = ['😊', '😔', '😢', '😡', '😌', '🥰', '😰', '😴'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Journal Entry', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 16),
              // Mood picker
              Text('How are you feeling?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: moods.map((m) => GestureDetector(
                onTap: () => setModalState(() => selectedMood = m),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedMood == m ? AppColors.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selectedMood == m ? AppColors.primary : Colors.transparent),
                  ),
                  child: Text(m, style: const TextStyle(fontSize: 22)),
                ),
              )).toList()),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(hintText: 'Title (optional)', hintStyle: GoogleFonts.poppins(color: AppColors.textLight), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.all(12)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(hintText: 'Write your thoughts here...', hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.all(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentCtrl.text.isNotEmpty) {
                      context.read<AppState>().addJournal(JournalModel(
                        id: DateTime.now().millisecondsSinceEpoch,
                        title: titleCtrl.text,
                        content: contentCtrl.text,
                        moodTag: selectedMood,
                        createdAt: DateTime.now(),
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: Text('Save Journal', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJournalDetail(BuildContext context, JournalModel journal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(journal.moodTag ?? '😊', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(journal.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            ]),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, d MMMM yyyy - HH:mm').format(journal.createdAt), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
            const Divider(height: 24),
            Text(journal.content, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium, height: 1.6)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final jarPaint = Paint()..color = const Color(0xFFF8BBD9)..style = PaintingStyle.fill;
    final outline = Paint()..color = const Color(0xFFE91E8C).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 2;
    // Jar body
    final jarPath = Path();
    jarPath.moveTo(size.width * 0.22, size.height * 0.28);
    jarPath.lineTo(size.width * 0.08, size.height * 0.92);
    jarPath.quadraticBezierTo(size.width * 0.5, size.height * 1.05, size.width * 0.92, size.height * 0.92);
    jarPath.lineTo(size.width * 0.78, size.height * 0.28);
    jarPath.close();
    canvas.drawPath(jarPath, jarPaint);
    canvas.drawPath(jarPath, outline);
    // Lid
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.15, size.height * 0.18, size.width * 0.7, size.height * 0.12), const Radius.circular(6)), Paint()..color = const Color(0xFFE91E8C));
    // Balls in jar
    final ballColors = [const Color(0xFF80DEEA), const Color(0xFFE91E8C), const Color(0xFF80CBC4), const Color(0xFFF48FB1), const Color(0xFF4FC3F7), const Color(0xFFE91E8C), const Color(0xFF80DEEA), const Color(0xFF80CBC4), const Color(0xFFF48FB1), const Color(0xFFE91E8C)];
    final positions = [
      Offset(size.width * 0.28, size.height * 0.5), Offset(size.width * 0.42, size.height * 0.45),
      Offset(size.width * 0.57, size.height * 0.48), Offset(size.width * 0.70, size.height * 0.52),
      Offset(size.width * 0.35, size.height * 0.62), Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.65, size.height * 0.6), Offset(size.width * 0.28, size.height * 0.75),
      Offset(size.width * 0.45, size.height * 0.78), Offset(size.width * 0.62, size.height * 0.74),
    ];
    for (int i = 0; i < positions.length && i < ballColors.length; i++) {
      canvas.drawCircle(positions[i], size.width * 0.1, Paint()..color = ballColors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
