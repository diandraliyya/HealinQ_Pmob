import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_data.dart';
import '../../widgets/common_widgets.dart';
import 'booking_form_screen.dart';

class CounselorListScreen extends StatelessWidget {
  final bool isOffline;

  const CounselorListScreen({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    final counselors = AppData.counselors.where((counselor) {
      if (isOffline) {
        return counselor.type == 'Offline' || counselor.type == 'Both';
      }

      return counselor.type == 'Online' || counselor.type == 'Both';
    }).toList();

    return Scaffold(
      body: Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isOffline
                            ? 'Offline Consultation'
                            : 'Online Consultation',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const ScoreCard(xp: 1240),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Pilih counselor terlebih dahulu, lalu tentukan jadwal konsultasi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: counselors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: counselors.length,
                        itemBuilder: (context, index) {
                          final counselor = counselors[index];

                          return CounselorCard(
                            name: counselor.name,
                            specialization: counselor.specialization,
                            rating: counselor.rating,
                            onBook: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookingFormScreen(
                                    counselor: counselor,
                                    isOffline: isOffline,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.textLight,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'No Counselor Available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}