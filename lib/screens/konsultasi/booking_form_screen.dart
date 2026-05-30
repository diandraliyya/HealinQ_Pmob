import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'booking_ticket_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final dynamic counselor;
  final bool isOffline;

  const BookingFormScreen({
    super.key,
    required this.counselor,
    required this.isOffline,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? _selectedDate;
  String? _selectedHour;
  bool _isLoading = false;

  final _notesCtrl = TextEditingController();

  final _availableHours = [
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

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isApiCounselor => widget.counselor is Map;

  int get _counselorId {
    if (_isApiCounselor) return widget.counselor['id'];
    return widget.counselor.id;
  }

  String get _counselorName {
    if (_isApiCounselor) return widget.counselor['name'] ?? '-';
    return widget.counselor.name;
  }

  String get _counselorSpecialization {
    if (_isApiCounselor) return widget.counselor['specialization'] ?? '-';
    return widget.counselor.specialization;
  }

  String get _counselorLocation {
    if (_isApiCounselor) return widget.counselor['location'] ?? '-';
    return widget.counselor.location;
  }

  double get _counselorRating {
    if (_isApiCounselor) {
      return double.tryParse(widget.counselor['rating'].toString()) ?? 0.0;
    }

    return widget.counselor.rating;
  }

  CounselorModel get _counselorModel {
    if (!_isApiCounselor) return widget.counselor;

    return CounselorModel(
      id: _counselorId,
      name: _counselorName,
      specialization: _counselorSpecialization,
      rating: _counselorRating,
      type: 'Both',
      location: _counselorLocation,
      bio: widget.counselor['bio'] ?? '',
      yearsExperience: int.tryParse(
            widget.counselor['years_experience'].toString(),
          ) ??
          0,
      priceOnline: double.tryParse(
            widget.counselor['online_price'].toString(),
          ) ??
          0,
      priceOffline: double.tryParse(
            widget.counselor['offline_price'].toString(),
          ) ??
          0,
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _bookNow() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final hourParts = _selectedHour!.split('.');

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(hourParts[0]),
      0,
    );

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createConsultation(
        counselorId: _counselorId,
        type: widget.isOffline ? 'Offline' : 'Online',
        scheduledAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledAt),
        notes: _notesCtrl.text,
      );

      final data = result['data'];

      final consultation = ConsultationModel(
        id: data['id'],
        counselor: _counselorModel,
        type: data['type'],
        scheduledAt: DateTime.parse(data['scheduled_at']),
        status: data['status'],
        notes: data['notes'],
        bookingCode: data['booking_code'],
      );

      if (!mounted) return;

      context.read<AppState>().addConsultation(consultation);

      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingTicketScreen(
            consultation: consultation,
            isOffline: widget.isOffline,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationText = _counselorLocation.contains(',')
        ? _counselorLocation.split(',').last.trim()
        : _counselorLocation;

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
                        'Konsultasi',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.secondaryLight,
                              child: Icon(
                                Icons.person,
                                color: AppColors.teal,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _counselorName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.textLight,
                                        size: 14,
                                      ),
                                      Text(
                                        locationText,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          i < _counselorRating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: AppColors.starYellow,
                                          size: 16,
                                        ),
                                      ),
                                      Text(
                                        ' $_counselorRating',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.starYellow,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _counselorSpecialization,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Form',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Consultation Day',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select date...'
                                      : DateFormat('EEEE, d MMMM yyyy')
                                          .format(_selectedDate!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _selectedDate == null
                                        ? AppColors.textLight
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Consultation Hour',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableHours.map((h) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedHour = h),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedHour == h
                                          ? AppColors.primary
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      h,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: _selectedHour == h
                                            ? AppColors.white
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'What would you like to talk about?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _notesCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Share your concerns here...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: AppColors.textLight,
                                    fontSize: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                  filled: true,
                                  fillColor: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    )
                                  : AppButton(
                                      text: 'Book Now',
                                      onPressed: _bookNow,
                                      width: 160,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
