import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class CounselorScheduleScreen extends StatefulWidget {
  const CounselorScheduleScreen({super.key});

  @override
  State<CounselorScheduleScreen> createState() =>
      _CounselorScheduleScreenState();
}

class _CounselorScheduleScreenState extends State<CounselorScheduleScreen> {
  bool _isAvailableNow = true;

  final List<_ScheduleDay> _scheduleDays = [
    _ScheduleDay(
      day: 'Monday',
      isActive: true,
      selectedHours: ['08.00', '09.00', '10.00', '13.00', '14.00'],
    ),
    _ScheduleDay(
      day: 'Tuesday',
      isActive: true,
      selectedHours: ['09.00', '10.00', '11.00', '15.00'],
    ),
    _ScheduleDay(
      day: 'Wednesday',
      isActive: true,
      selectedHours: ['08.00', '10.00', '13.00', '16.00'],
    ),
    _ScheduleDay(
      day: 'Thursday',
      isActive: true,
      selectedHours: ['09.00', '11.00', '14.00', '15.00'],
    ),
    _ScheduleDay(
      day: 'Friday',
      isActive: true,
      selectedHours: ['08.00', '09.00', '10.00'],
    ),
    _ScheduleDay(
      day: 'Saturday',
      isActive: false,
      selectedHours: [],
    ),
    _ScheduleDay(
      day: 'Sunday',
      isActive: false,
      selectedHours: [],
    ),
  ];

  final List<String> _availableHours = const [
    '08.00',
    '09.00',
    '10.00',
    '11.00',
    '12.00',
    '13.00',
    '14.00',
    '15.00',
    '16.00',
    '17.00',
  ];

  int get _activeDays => _scheduleDays.where((day) => day.isActive).length;

  int get _totalSlots {
    int total = 0;
    for (final day in _scheduleDays) {
      if (day.isActive) {
        total += day.selectedHours.length;
      }
    }
    return total;
  }

  void _toggleDay(int index, bool value) {
    setState(() {
      _scheduleDays[index].isActive = value;

      if (!value) {
        _scheduleDays[index].selectedHours.clear();
      } else if (_scheduleDays[index].selectedHours.isEmpty) {
        _scheduleDays[index].selectedHours.addAll(['09.00', '10.00']);
      }
    });
  }

  void _toggleHour(int dayIndex, String hour) {
    setState(() {
      final selectedHours = _scheduleDays[dayIndex].selectedHours;

      if (selectedHours.contains(hour)) {
        selectedHours.remove(hour);
      } else {
        selectedHours.add(hour);
        selectedHours.sort();
      }

      if (selectedHours.isEmpty) {
        _scheduleDays[dayIndex].isActive = false;
      } else {
        _scheduleDays[dayIndex].isActive = true;
      }
    });
  }

  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule saved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counselor = context.watch<AppState>().currentCounselor;

    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _ScheduleBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Schedule',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Atur jadwal available untuk konsultasi user.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _AvailabilityStatusCard(
                        counselorName: counselor?.name ?? 'Counselor',
                        isAvailableNow: _isAvailableNow,
                        onChanged: (value) {
                          setState(() {
                            _isAvailableNow = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _ScheduleStatCard(
                              title: 'Active Days',
                              value: '$_activeDays',
                              icon: Icons.today_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ScheduleStatCard(
                              title: 'Total Slots',
                              value: '$_totalSlots',
                              icon: Icons.access_time_rounded,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Weekly Availability',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih hari dan jam yang tersedia untuk menerima konsultasi.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_scheduleDays.length, (index) {
                        final scheduleDay = _scheduleDays[index];

                        return _ScheduleDayCard(
                          scheduleDay: scheduleDay,
                          availableHours: _availableHours,
                          onDayChanged: (value) => _toggleDay(index, value),
                          onHourTap: (hour) => _toggleHour(index, hour),
                        );
                      }),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveSchedule,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            'Save Schedule',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityStatusCard extends StatelessWidget {
  final String counselorName;
  final bool isAvailableNow;
  final ValueChanged<bool> onChanged;

  const _AvailabilityStatusCard({
    required this.counselorName,
    required this.isAvailableNow,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isAvailableNow
                ? AppColors.success.withOpacity(0.12)
                : AppColors.textLight.withOpacity(0.16),
            child: Icon(
              isAvailableNow
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              color: isAvailableNow ? AppColors.success : AppColors.textMedium,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counselorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvailableNow
                      ? 'Status kamu sekarang available'
                      : 'Status kamu sekarang not available',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailableNow,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ScheduleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ScheduleStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDayCard extends StatelessWidget {
  final _ScheduleDay scheduleDay;
  final List<String> availableHours;
  final ValueChanged<bool> onDayChanged;
  final ValueChanged<String> onHourTap;

  const _ScheduleDayCard({
    required this.scheduleDay,
    required this.availableHours,
    required this.onDayChanged,
    required this.onHourTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheduleDay.isActive
                    ? AppColors.primarySoft
                    : AppColors.surfaceMuted,
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: scheduleDay.isActive
                      ? AppColors.primary
                      : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scheduleDay.day,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                scheduleDay.isActive ? 'Active' : 'Off',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheduleDay.isActive
                      ? AppColors.success
                      : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: scheduleDay.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: onDayChanged,
              ),
            ],
          ),
          if (scheduleDay.isActive) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Hours',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableHours.map((hour) {
                final selected = scheduleDay.selectedHours.contains(hour);

                return GestureDetector(
                  onTap: () => onHourTap(hour),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Text(
                      hour,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tidak ada jadwal konsultasi di hari ini.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleDay {
  final String day;
  bool isActive;
  final List<String> selectedHours;

  _ScheduleDay({
    required this.day,
    required this.isActive,
    required this.selectedHours,
  });
}

class _ScheduleBackground extends StatelessWidget {
  const _ScheduleBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _ScheduleBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _ScheduleBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _ScheduleBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _ScheduleBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.60,
          heightFactor: 0.22,
          color: AppColors.blobPink,
          opacity: 0.30,
        ),
      ],
    );
  }
}

class _ScheduleBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _ScheduleBlob({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size.width * widthFactor,
          height: size.height * heightFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}