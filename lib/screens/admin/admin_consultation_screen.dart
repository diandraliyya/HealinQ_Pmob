import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AdminConsultationScreen extends StatefulWidget {
  const AdminConsultationScreen({super.key});

  @override
  State<AdminConsultationScreen> createState() =>
      _AdminConsultationScreenState();
}

class _AdminConsultationScreenState extends State<AdminConsultationScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_ConsultationItem> _consultations = [
    _ConsultationItem(
      id: 1,
      user: 'Alya Putri',
      counselor: 'Dr. Aulia Rahman',
      amount: 75000,
      date: 'Mar 28, 2026',
      status: 'Paid',
      method: 'E-Wallet',
      sessionType: 'Chat Counseling',
      reference: 'TRX-1001',
      consultationStatus: 'Completed',
    ),
    _ConsultationItem(
      id: 2,
      user: 'Nadhif Ramadhan',
      counselor: 'Dr. Nabila Putri',
      amount: 100000,
      date: 'Mar 27, 2026',
      status: 'Pending',
      method: 'Bank Transfer',
      sessionType: 'Video Consultation',
      reference: 'TRX-1002',
      consultationStatus: 'Scheduled',
    ),
    _ConsultationItem(
      id: 3,
      user: 'Citra Maharani',
      counselor: 'Dr. Farhan Yusuf',
      amount: 85000,
      date: 'Mar 26, 2026',
      status: 'Failed',
      method: 'E-Wallet',
      sessionType: 'Voice Session',
      reference: 'TRX-1003',
      consultationStatus: 'Cancelled',
    ),
    _ConsultationItem(
      id: 4,
      user: 'Raka Pratama',
      counselor: 'Dr. Keisha Amanda',
      amount: 120000,
      date: 'Mar 25, 2026',
      status: 'Paid',
      method: 'Credit Card',
      sessionType: 'Video Consultation',
      reference: 'TRX-1004',
      consultationStatus: 'Completed',
    ),
    _ConsultationItem(
      id: 5,
      user: 'Salwa Nabila',
      counselor: 'Dr. Salma Nadhira',
      amount: 90000,
      date: 'Mar 24, 2026',
      status: 'Pending',
      method: 'Bank Transfer',
      sessionType: 'Chat Counseling',
      reference: 'TRX-1005',
      consultationStatus: 'Scheduled',
    ),
    _ConsultationItem(
      id: 6,
      user: 'Kevin Saputra',
      counselor: 'Dr. Rafi Pradana',
      amount: 110000,
      date: 'Mar 23, 2026',
      status: 'Paid',
      method: 'Credit Card',
      sessionType: 'Video Consultation',
      reference: 'TRX-1006',
      consultationStatus: 'Completed',
    ),
  ];

  String _selectedStatus = 'All';

  List<_ConsultationItem> get _filteredConsultations {
    final query = _searchController.text.trim().toLowerCase();

    return _consultations.where((item) {
      final matchesSearch =
          item.user.toLowerCase().contains(query) ||
          item.counselor.toLowerCase().contains(query) ||
          item.reference.toLowerCase().contains(query) ||
          item.method.toLowerCase().contains(query) ||
          item.sessionType.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ? true : item.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _paidCount => _consultations.where((e) => e.status == 'Paid').length;
  int get _pendingCount =>
      _consultations.where((e) => e.status == 'Pending').length;
  int get _failedCount =>
      _consultations.where((e) => e.status == 'Failed').length;

  int get _totalRevenue => _consultations
      .where((e) => e.status == 'Paid')
      .fold(0, (sum, item) => sum + item.amount);

  String _formatCurrency(int value) {
    final number = value.toString();
    final buffer = StringBuffer();
    int counter = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      buffer.write(number[i]);
      counter++;
      if (counter % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Color _paymentBg(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFFDFF7EB);
      case 'Pending':
        return const Color(0xFFFFF0D9);
      case 'Failed':
        return const Color(0xFFFFE1EA);
      default:
        return AppColors.primarySoft;
    }
  }

  Color _paymentText(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF1F9D62);
      case 'Pending':
        return const Color(0xFFD68A1F);
      case 'Failed':
        return const Color(0xFFD64B7F);
      default:
        return AppColors.primary;
    }
  }

  Color _consultationBg(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFFDFF1FF);
      case 'Scheduled':
        return const Color(0xFFF3E8FF);
      case 'Cancelled':
        return const Color(0xFFF3F3F3);
      default:
        return AppColors.primarySoft;
    }
  }

  Color _consultationText(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.brandBlue;
      case 'Scheduled':
        return const Color(0xFF7B4DDB);
      case 'Cancelled':
        return AppColors.textMedium;
      default:
        return AppColors.primary;
    }
  }

  void _showConsultationDetail(_ConsultationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Consultation Detail',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _detailTile('Reference', item.reference),
                _detailTile('User', item.user),
                _detailTile('Counselor', item.counselor),
                _detailTile('Session Type', item.sessionType),
                _detailTile('Payment Method', item.method),
                _detailTile('Amount', _formatCurrency(item.amount)),
                _detailTile('Date', item.date),
                _detailTile('Payment Status', item.status),
                _detailTile('Consultation Status', item.consultationStatus),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
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
          const SizedBox(height: 4),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminConsultationBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Consultation History',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Text(
                        'Track consultations, bookings, and payment status in one place',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.22,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Total Revenue',
                            value: _formatCurrency(_totalRevenue),
                            icon: Icons.payments_rounded,
                            color: AppColors.brandBlue,
                          ),
                          _buildStatCard(
                            title: 'Paid',
                            value: '$_paidCount',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                          _buildStatCard(
                            title: 'Pending',
                            value: '$_pendingCount',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFD68A1F),
                          ),
                          _buildStatCard(
                            title: 'Failed',
                            value: '$_failedCount',
                            icon: Icons.error_rounded,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText:
                                    'Search user, counselor, reference, or session...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: AppColors.surfaceMuted,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _FilterChipItem(
                                    label: 'All',
                                    selected: _selectedStatus == 'All',
                                    onTap: () =>
                                        setState(() => _selectedStatus = 'All'),
                                  ),
                                  _FilterChipItem(
                                    label: 'Paid',
                                    selected: _selectedStatus == 'Paid',
                                    onTap: () => setState(
                                      () => _selectedStatus = 'Paid',
                                    ),
                                  ),
                                  _FilterChipItem(
                                    label: 'Pending',
                                    selected: _selectedStatus == 'Pending',
                                    onTap: () => setState(
                                      () => _selectedStatus = 'Pending',
                                    ),
                                  ),
                                  _FilterChipItem(
                                    label: 'Failed',
                                    selected: _selectedStatus == 'Failed',
                                    onTap: () => setState(
                                      () => _selectedStatus = 'Failed',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._filteredConsultations.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(20),
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
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primarySoft,
                                    child: Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.user,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.counselor} • ${item.reference}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _paymentBg(item.status),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _paymentText(item.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.video_call_rounded,
                                    size: 16,
                                    color: AppColors.textMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.sessionType,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: AppColors.textMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.method,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(item.amount),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: AppColors.textMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.date,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _consultationBg(
                                        item.consultationStatus,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      item.consultationStatus,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _consultationText(
                                          item.consultationStatus,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showConsultationDetail(item),
                                  child: Text(
                                    'View Detail',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_filteredConsultations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No consultations found',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
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
          ),
        ],
      ),
    );
  }
}

class _ConsultationItem {
  final int id;
  final String user;
  final String counselor;
  final int amount;
  final String date;
  final String status;
  final String method;
  final String sessionType;
  final String reference;
  final String consultationStatus;

  _ConsultationItem({
    required this.id,
    required this.user,
    required this.counselor,
    required this.amount,
    required this.date,
    required this.status,
    required this.method,
    required this.sessionType,
    required this.reference,
    required this.consultationStatus,
  });
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.primary,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

class _AdminConsultationBackground extends StatelessWidget {
  const _AdminConsultationBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _AdminConsultationBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminConsultationBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminConsultationBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _AdminConsultationBlob(
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

class _AdminConsultationBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminConsultationBlob({
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