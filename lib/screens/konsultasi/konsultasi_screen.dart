import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'counselor_list_screen.dart';
import '../chat/message_list_screen.dart';

class KonsultasiScreen extends StatelessWidget {
  const KonsultasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgGradientStart, AppColors.primarySoft],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Konsultasi',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const ScoreCard(xp: 1240),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Message button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MessageListScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.brandTeal,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.message_rounded,
                                color: AppColors.white, size: 18),
                            Text(' Message',
                                style: GoogleFonts.poppins(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildEnvelopeIllustration(),
                    const SizedBox(height: 5),
                    Text('Need Someone to Talk?',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    Text('Flexible consultations, safe and private',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                            child: _buildConsultationCard(context,
                                isOffline: true)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildConsultationCard(context,
                                isOffline: false)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeIllustration() {
    return Center(
      child: Image.asset(
        'assets/images/envelope.png',
        width: 360,
        height: 300,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 260,
            height: 200,
          );
        },
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context,
      {required bool isOffline}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => CounselorListScreen(isOffline: isOffline)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(
                  isOffline ? Icons.people_rounded : Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                  size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              isOffline ? 'OFFLINE\nCONSULTATION' : 'ONLINE\nCONSULTATION',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              isOffline
                  ? 'Face-to-Face,\nProfessional\nSupport'
                  : 'Flexible & Private\nSupport from\nAnywhere',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Meet our counselor directly at our clinic for a more personal consultation experience.'
                  : 'Connect with our professional counselors via chat — wherever you feel most comfortable.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('View',
                  style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}