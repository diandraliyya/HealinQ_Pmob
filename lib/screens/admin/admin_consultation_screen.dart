import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/admin_consultation_model.dart';
import '../../services/admin_consultation_service.dart';
import '../../theme/app_theme.dart';

class AdminConsultationScreen extends StatefulWidget {
  const AdminConsultationScreen({super.key});

  @override
  State<AdminConsultationScreen> createState() =>
      _AdminConsultationScreenState();
}

class _AdminConsultationScreenState extends State<AdminConsultationScreen> {
  final AdminConsultationService _service = AdminConsultationService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminConsultationModel> _items = <AdminConsultationModel>[];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  String? _processingPaymentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<AdminConsultationModel> result =
          await _service.getAllConsultations();

      if (!mounted) return;

      setState(() {
        _items = result;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<AdminConsultationModel> get _visibleItems {
    final String query = _searchController.text.trim().toLowerCase();

    return _items.where((AdminConsultationModel item) {
      final bool matchesSearch = query.isEmpty ||
          item.userName.toLowerCase().contains(query) ||
          item.userEmail.toLowerCase().contains(query) ||
          item.counselorName.toLowerCase().contains(query) ||
          item.bookingCode.toLowerCase().contains(query);

      final bool matchesFilter;

      switch (_selectedFilter) {
        case 'waiting':
          matchesFilter = item.paymentStatus == 'pending_verification';
          break;
        case 'paid':
          matchesFilter = item.paymentStatus == 'paid';
          break;
        case 'rejected':
          matchesFilter = item.paymentStatus == 'rejected';
          break;
        case 'unpaid':
          matchesFilter = item.paymentStatus == 'unpaid';
          break;
        case 'all':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _waitingCount => _items
      .where(
        (AdminConsultationModel item) =>
            item.paymentStatus == 'pending_verification',
      )
      .length;

  int get _paidCount => _items
      .where(
        (AdminConsultationModel item) => item.paymentStatus == 'paid',
      )
      .length;

  int get _rejectedCount => _items
      .where(
        (AdminConsultationModel item) => item.paymentStatus == 'rejected',
      )
      .length;

  int get _unpaidCount => _items
      .where(
        (AdminConsultationModel item) => item.paymentStatus == 'unpaid',
      )
      .length;

  double get _totalRevenue => _items
      .where(
        (AdminConsultationModel item) => item.paymentStatus == 'paid',
      )
      .fold<double>(
        0,
        (double total, AdminConsultationModel item) => total + item.amount,
      );

  Future<void> _approvePayment(AdminConsultationModel item) async {
    if (_isMutating || item.paymentId.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Approve Payment?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Pembayaran ${item.bookingCode} akan disetujui. '
            'Status konsultasi berubah menjadi confirmed.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.55,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _runMutation(
      paymentId: item.paymentId,
      action: () => _service.approvePayment(item.paymentId),
      successMessage: 'Pembayaran berhasil disetujui.',
    );
  }

  Future<void> _rejectPayment(AdminConsultationModel item) async {
    if (_isMutating || item.paymentId.isEmpty) return;

    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Reject Payment',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan',
              hintText: 'Contoh: Bukti transfer tidak terbaca.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value = reasonController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || !mounted) return;

    await _runMutation(
      paymentId: item.paymentId,
      action: () => _service.rejectPayment(
        paymentId: item.paymentId,
        reason: reason,
      ),
      successMessage: 'Pembayaran ditolak. User dapat mengunggah ulang bukti.',
    );
  }

  Future<void> _runMutation({
    required String paymentId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _isMutating = true;
      _processingPaymentId = paymentId;
    });

    try {
      await action();
      await _loadData(showLoading: false);

      if (!mounted) return;

      _showMessage(successMessage, isError: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
          _processingPaymentId = null;
        });
      }
    }
  }

  Future<void> _showDetail(AdminConsultationModel item) async {
    String? proofUrl;
    String? proofError;

    if (item.proofPath != null && item.proofPath!.trim().isNotEmpty) {
      try {
        proofUrl = await _service.getPaymentProofUrl(item.proofPath);
      } catch (error) {
        proofError = _cleanError(error);
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                children: <Widget>[
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
                    'Payment Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _detailBox('Booking Code', item.bookingCode),
                  _detailBox('User', '${item.userName}\n${item.userEmail}'),
                  _detailBox(
                    'Counselor',
                    '${item.counselorName}\n${item.specialization}',
                  ),
                  _detailBox(
                    'Schedule',
                    DateFormat('EEEE, d MMM yyyy • HH:mm').format(
                      item.scheduledStart,
                    ),
                  ),
                  _detailBox(
                    'Consultation',
                    '${item.consultationType.toUpperCase()} • '
                    '${item.consultationStatusLabel}',
                  ),
                  _detailBox(
                    'Payment',
                    '${_formatCurrency(item.amount)} • '
                    '${item.paymentStatusLabel}',
                  ),
                  _detailBox(
                    'Method',
                    item.paymentMethodName ?? '-',
                  ),
                  _detailBox(
                    'Submitted At',
                    item.submittedAt == null
                        ? '-'
                        : DateFormat('d MMM yyyy, HH:mm').format(
                            item.submittedAt!,
                          ),
                  ),
                  if (item.rejectionReason?.trim().isNotEmpty == true)
                    _detailBox(
                      'Rejection Reason',
                      item.rejectionReason!,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Proof',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: proofUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              proofUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? progress,
                              ) {
                                if (progress == null) return child;
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(50),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => _proofPlaceholder(
                                'Bukti pembayaran gagal ditampilkan.',
                              ),
                            ),
                          )
                        : _proofPlaceholder(
                            proofError ?? 'Bukti pembayaran belum tersedia.',
                          ),
                  ),
                  const SizedBox(height: 18),
                  if (item.isWaitingVerification)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isMutating
                                ? null
                                : () async {
                                    Navigator.pop(sheetContext);
                                    await _rejectPayment(item);
                                  },
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isMutating
                                ? null
                                : () async {
                                    Navigator.pop(sheetContext);
                                    await _approvePayment(item);
                                  },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _proofPlaceholder(String message) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.image_not_supported_outlined,
            size: 46,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
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
          backgroundColor:
              isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AdminConsultationBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _loadData(showLoading: false),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Consultation & Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Review payment proofs and booking status.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading || _isMutating ? null : _loadData,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      children: <Widget>[
        _buildStats(),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        if (_visibleItems.isEmpty)
          _buildEmptyState()
        else
          ..._visibleItems.map(_buildCard),
      ],
    );
  }

  Widget _buildStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: <Widget>[
        _statCard(
          'Revenue',
          _formatCurrency(_totalRevenue),
          Icons.payments_rounded,
          AppColors.brandBlue,
        ),
        _statCard(
          'Waiting',
          '$_waitingCount',
          Icons.hourglass_top_rounded,
          const Color(0xFFD68A1F),
        ),
        _statCard(
          'Paid',
          '$_paidCount',
          Icons.check_circle_rounded,
          AppColors.success,
        ),
        _statCard(
          'Rejected',
          '$_rejectedCount',
          Icons.cancel_rounded,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search user, counselor, or booking code...',
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
              children: <Widget>[
                _filterChip('all', 'All (${_items.length})'),
                _filterChip('waiting', 'Waiting ($_waitingCount)'),
                _filterChip('paid', 'Paid ($_paidCount)'),
                _filterChip('rejected', 'Rejected ($_rejectedCount)'),
                _filterChip(
                  'unpaid',
                  'Unpaid ($_unpaidCount)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
        side: BorderSide.none,
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AdminConsultationModel item) {
    final Color paymentColor = _paymentColor(item.paymentStatus);
    final bool processing = _processingPaymentId == item.paymentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${item.counselorName} • ${item.bookingCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: paymentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.paymentStatusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: paymentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: <Widget>[
                _cardInfoRow(
                  Icons.calendar_today_rounded,
                  DateFormat('d MMM yyyy, HH:mm').format(
                    item.scheduledStart,
                  ),
                ),
                const SizedBox(height: 7),
                _cardInfoRow(
                  Icons.payments_rounded,
                  '${_formatCurrency(item.amount)} • '
                  '${item.consultationStatusLabel}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processing ? null : () => _showDetail(item),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(
                    'View Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (item.isWaitingVerification) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: processing ? null : () => _approvePayment(item),
                    icon: processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      processing ? 'Processing' : 'Approve',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardInfoRow(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailBox(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 45),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.search_off_rounded,
            size: 50,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 10),
          Text(
            'No consultation found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
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
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'pending_verification':
        return const Color(0xFFD68A1F);
      case 'paid':
        return AppColors.success;
      case 'rejected':
      case 'expired':
        return AppColors.error;
      case 'unpaid':
        return AppColors.textMedium;
      default:
        return AppColors.primary;
    }
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

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}

class _AdminConsultationBackground extends StatelessWidget {
  const _AdminConsultationBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _AdminBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
      ],
    );
  }
}

class _AdminBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminBlob({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size.width * widthFactor,
          height: size.height * heightFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
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
