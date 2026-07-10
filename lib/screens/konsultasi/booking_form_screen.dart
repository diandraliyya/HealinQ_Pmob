import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/consultation_slot_model.dart';
import '../../models/user_counselor_model.dart';
import '../../services/user_consultation_service.dart';
import '../../theme/app_theme.dart';
import 'payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final UserCounselorModel counselor;
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
  final UserConsultationService _service = UserConsultationService();

  final TextEditingController _notesController = TextEditingController();

  List<ConsultationSlotModel> _slots = <ConsultationSlotModel>[];

  ConsultationSlotModel? _selectedSlot;

  bool _isLoading = true;
  bool _isBooking = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<ConsultationSlotModel> result =
          await _service.getAvailableSlots(
        widget.counselor.id,
        widget.isOffline,
      );

      if (!mounted) return;

      result.sort(
        (
          ConsultationSlotModel first,
          ConsultationSlotModel second,
        ) {
          return first.startAt.compareTo(
            second.startAt,
          );
        },
      );

      setState(() {
        _slots = result;

        final String? selectedId = _selectedSlot?.id;

        if (selectedId == null ||
            !result.any(
              (ConsultationSlotModel slot) => slot.id == selectedId,
            )) {
          _selectedSlot = null;
        }

        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBooking() async {
    final ConsultationSlotModel? selectedSlot = _selectedSlot;

    if (selectedSlot == null) {
      _showMessage(
        'Pilih slot konsultasi terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_isBooking) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final Map<String, dynamic> result = await _service.createBooking(
        slotId: selectedSlot.id,
        notes: _notesController.text,
      );

      if (!mounted) return;

      final String consultationId = result['consultation_id']?.toString() ?? '';

      final String paymentId = result['payment_id']?.toString() ?? '';

      final double amount = double.tryParse(
            result['amount'].toString(),
          ) ??
          0;

      if (consultationId.isEmpty || paymentId.isEmpty) {
        throw Exception(
          'Data pembayaran tidak ditemukan.',
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            consultationId: consultationId,
            paymentId: paymentId,
            amount: amount,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );

      await _loadSlots(
        showLoading: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
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
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFB2EBF2),
              Color(0xFFFCE4EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () {
                    return _loadSlots(
                      showLoading: false,
                    );
                  },
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        16,
        8,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              'Choose Schedule',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isBooking ? null : _loadSlots,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white.withOpacity(0.9),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 80),
          _buildErrorState(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        4,
        18,
        28,
      ),
      children: <Widget>[
        _buildCounselorCard(),
        const SizedBox(height: 18),
        Text(
          'Available Slots',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Satu slot hanya dapat dipesan oleh satu user.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 13),
        if (_slots.isEmpty) _buildEmptySlots() else ..._buildGroupedSlots(),
        const SizedBox(height: 18),
        Text(
          'What would you like to talk about?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Share your concerns here (optional)...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppColors.white.withOpacity(0.94),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isBooking || _slots.isEmpty ? null : _createBooking,
            icon: _isBooking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward_rounded,
                  ),
            label: Text(
              _isBooking ? 'Creating Booking...' : 'Continue to Payment',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounselorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 31,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(
              Icons.medical_services_rounded,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.counselor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.counselor.specialization,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(
                      widget.isOffline
                          ? Icons.location_on_rounded
                          : Icons.videocam_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isOffline
                          ? 'Offline Consultation'
                          : 'Online Consultation',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSlots() {
    final Map<String, List<ConsultationSlotModel>> groupedSlots =
        <String, List<ConsultationSlotModel>>{};

    for (final ConsultationSlotModel slot in _slots) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(
        slot.startAt,
      );

      groupedSlots.putIfAbsent(
        dateKey,
        () => <ConsultationSlotModel>[],
      );

      groupedSlots[dateKey]!.add(slot);
    }

    final List<Widget> widgets = <Widget>[];

    for (final MapEntry<String, List<ConsultationSlotModel>> entry
        in groupedSlots.entries) {
      final DateTime date = entry.value.first.startAt;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            top: 6,
            bottom: 8,
          ),
          child: Text(
            DateFormat(
              'EEEE, d MMMM yyyy',
            ).format(date),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      );

      widgets.add(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entry.value.map(
            (
              ConsultationSlotModel slot,
            ) {
              final bool isSelected = _selectedSlot?.id == slot.id;

              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.white.withOpacity(0.94),
                label: Text(
                  '${DateFormat('HH:mm').format(slot.startAt)}–'
                  '${DateFormat('HH:mm').format(slot.endAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textDark,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  side: BorderSide.none,
                ),
              );
            },
          ).toList(),
        ),
      );

      widgets.add(
        const SizedBox(height: 12),
      );
    }

    return widgets;
  }

  Widget _buildSummaryCard() {
    final double amount = widget.isOffline
        ? widget.counselor.priceOffline
        : widget.counselor.priceOnline;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          _summaryRow(
            'Type',
            widget.isOffline ? 'Offline' : 'Online',
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Schedule',
            _selectedSlot == null
                ? 'Not selected'
                : DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(
                    _selectedSlot!.startAt,
                  ),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Amount',
            _formatCurrency(amount),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlots() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.textLight,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            'No Available Slots',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Slot mungkin baru saja dipesan. '
            'Tarik halaman untuk refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadSlots,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final String number = value.toStringAsFixed(0);

    final StringBuffer result = StringBuffer();

    for (int index = 0; index < number.length; index++) {
      if (index > 0 && (number.length - index) % 3 == 0) {
        result.write('.');
      }

      result.write(number[index]);
    }

    return 'Rp$result';
  }
}
