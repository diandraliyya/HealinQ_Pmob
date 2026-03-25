import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../utils/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'booking_ticket_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final CounselorModel counselor;
  final bool isOffline;

  const BookingFormScreen({super.key, required this.counselor, required this.isOffline});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? _selectedDate;
  String? _selectedHour;
  final _notesCtrl = TextEditingController();
  final _availableHours = ['08.00', '09.00', '10.00', '11.00', '12.00', '13.00', '14.00', '15.00', '16.00', '17.00'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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

  void _bookNow() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time'), backgroundColor: AppColors.error));
      return;
    }
    final hourParts = _selectedHour!.split('.');
    final scheduledAt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, int.parse(hourParts[0]), 0);
    final consultation = ConsultationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      counselor: widget.counselor,
      type: widget.isOffline ? 'Offline' : 'Online',
      scheduledAt: scheduledAt,
      status: 'Pending',
      notes: _notesCtrl.text,
      bookingCode: '${DateTime.now().millisecondsSinceEpoch}'.substring(0, 12).replaceAllMapped(RegExp(r'.{3}'), (m) => '${m.group(0)}.'),
    );
    context.read<AppState>().addConsultation(consultation);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingTicketScreen(consultation: consultation, isOffline: widget.isOffline)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary)),
                    Expanded(child: Text('Konsultasi', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    const ScoreCard(xp: 1240),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Counselor Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 30, backgroundColor: AppColors.secondaryLight, child: Icon(Icons.person, color: AppColors.teal, size: 36)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.counselor.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                                  Row(children: [
                                    const Icon(Icons.location_on_rounded, color: AppColors.textLight, size: 14),
                                    Text(widget.counselor.location.split(',').last.trim(), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMedium)),
                                  ]),
                                  Row(children: [
                                    ...List.generate(5, (i) => Icon(i < widget.counselor.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.starYellow, size: 16)),
                                    Text(' ${widget.counselor.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.starYellow)),
                                  ]),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                                    child: Text(widget.counselor.specialization, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Booking Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Booking Form', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 16),
                            Text('Consultation Day', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  _selectedDate == null ? 'Select date...' : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                                  style: GoogleFonts.poppins(fontSize: 14, color: _selectedDate == null ? AppColors.textLight : AppColors.textDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Consultation Hour', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _availableHours.map((h) => GestureDetector(
                                onTap: () => setState(() => _selectedHour = h),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedHour == h ? AppColors.primary : AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(h, style: GoogleFonts.poppins(fontSize: 13, color: _selectedHour == h ? AppColors.white : AppColors.textDark, fontWeight: FontWeight.w500)),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text('What would you like to talk about?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                              child: TextField(
                                controller: _notesCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Share your concerns here...',
                                  hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.all(16),
                                  filled: true, fillColor: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: AppButton(text: 'Book Now', onPressed: _bookNow, width: 160, color: AppColors.primary),
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
