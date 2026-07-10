import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/admin_counselor_model.dart';
import '../../services/counselor_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class AdminCounselorsScreen extends StatefulWidget {
  const AdminCounselorsScreen({super.key});

  @override
  State<AdminCounselorsScreen> createState() =>
      _AdminCounselorsScreenState();
}

class _AdminCounselorsScreenState extends State<AdminCounselorsScreen> {
  final CounselorService _counselorService = CounselorService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminCounselorModel> _counselors = <AdminCounselorModel>[];

  String _selectedStatus = 'all';
  String? _errorMessage;
  String? _processingCounselorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCounselors({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<AdminCounselorModel> result =
          await _counselorService.getAllCounselors();

      if (!mounted) return;

      setState(() {
        _counselors = result;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<AdminCounselorModel> get _filteredCounselors {
    final String query = _searchController.text.trim().toLowerCase();

    return _counselors.where((AdminCounselorModel counselor) {
      final bool matchesSearch =
          counselor.name.toLowerCase().contains(query) ||
              counselor.email.toLowerCase().contains(query) ||
              counselor.username.toLowerCase().contains(query) ||
              counselor.specialization.toLowerCase().contains(query) ||
              counselor.location.toLowerCase().contains(query);

      final bool matchesStatus = _selectedStatus == 'all' ||
          counselor.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalCounselors => _counselors.length;

  int get _activeCounselors =>
      _counselors.where((item) => item.status == 'active').length;

  int get _inactiveCounselors => _counselors
      .where((item) =>
          item.status == 'inactive' || item.status == 'suspended')
      .length;

  int get _pendingCounselors =>
      _counselors.where((item) => item.status == 'pending').length;

  Future<void> _showAddCounselorDialog() async {
    final String? createdCounselorName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddCounselorDialog(
        counselorService: _counselorService,
      ),
    );

    if (!mounted || createdCounselorName == null) return;

    context.read<AppState>().addAdminActivity(
          'Admin added counselor: $createdCounselorName',
        );

    _showMessage(
      '$createdCounselorName berhasil ditambahkan.',
      isError: false,
    );

    await _loadCounselors(showLoading: false);
  }

  Future<void> _showEditCounselorDialog(
    AdminCounselorModel counselor,
  ) async {
    final bool? wasUpdated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditCounselorDialog(
        counselor: counselor,
        counselorService: _counselorService,
      ),
    );

    if (!mounted || wasUpdated != true) return;

    context.read<AppState>().addAdminActivity(
          'Admin edited counselor: ${counselor.name}',
        );

    _showMessage(
      'Data counselor berhasil diperbarui.',
      isError: false,
    );

    await _loadCounselors(showLoading: false);
  }

  Future<void> _showCounselorDetail(
    AdminCounselorModel counselor,
  ) async {
    final bool? editRequested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.secondaryLight,
                          child: Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.teal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counselor.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                counselor.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: counselor.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _detailTile(
                      'Username',
                      counselor.username.isEmpty ? '-' : counselor.username,
                    ),
                    _detailTile('Specialization', counselor.specialization),
                    _detailTile(
                      'Experience',
                      '${counselor.yearsExperience} years',
                    ),
                    _detailTile(
                      'Consultation Type',
                      counselor.consultationType,
                    ),
                    _detailTile('Location', counselor.location),
                    _detailTile(
                      'Online Price',
                      _formatCurrency(counselor.priceOnline),
                    ),
                    _detailTile(
                      'Offline Price',
                      _formatCurrency(counselor.priceOffline),
                    ),
                    _detailTile(
                      'Rating',
                      '${counselor.rating.toStringAsFixed(1)} '
                          '(${counselor.ratingCount} reviews)',
                    ),
                    _detailTile(
                      'Availability',
                      counselor.isAvailable ? 'Available' : 'Not available',
                    ),
                    _detailTile('Joined', _formatDate(counselor.createdAt)),
                    _detailTile(
                      'Approved At',
                      counselor.approvedAt == null
                          ? 'Not approved'
                          : _formatDateTime(counselor.approvedAt!),
                    ),
                    _detailTile(
                      'Approved By',
                      counselor.approvedBy ?? '-',
                    ),
                    _detailTile(
                      'Professional Bio',
                      counselor.bio.trim().isEmpty
                          ? 'No bio available'
                          : counselor.bio,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(
                          'Edit Counselor',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
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
      },
    );

    if (!mounted || editRequested != true) return;
    await _showEditCounselorDialog(counselor);
  }

  Future<void> _approveCounselor(
    AdminCounselorModel counselor,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      title: 'Approve Counselor',
      message: 'Approve ${counselor.name} as an active counselor?',
      confirmText: 'Approve',
      confirmColor: AppColors.success,
    );

    if (!confirmed) return;

    await _runStatusAction(
      counselor: counselor,
      action: () => _counselorService.approveCounselor(counselor.id),
      successMessage: '${counselor.name} berhasil disetujui.',
      activity: 'Admin approved counselor: ${counselor.name}',
    );
  }

  Future<void> _rejectCounselor(
    AdminCounselorModel counselor,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      title: 'Reject Counselor',
      message:
          'Reject ${counselor.name}? Akun akan diubah menjadi inactive.',
      confirmText: 'Reject',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    await _runStatusAction(
      counselor: counselor,
      action: () =>
          _counselorService.setCounselorInactive(counselor.id),
      successMessage: '${counselor.name} telah ditolak.',
      activity: 'Admin rejected counselor: ${counselor.name}',
    );
  }

  Future<void> _setInactive(
    AdminCounselorModel counselor,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      title: 'Deactivate Counselor',
      message:
          'Deactivate ${counselor.name}? Counselor tidak akan tampil untuk pengguna.',
      confirmText: 'Deactivate',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    await _runStatusAction(
      counselor: counselor,
      action: () =>
          _counselorService.setCounselorInactive(counselor.id),
      successMessage: '${counselor.name} berhasil dinonaktifkan.',
      activity: 'Admin deactivated counselor: ${counselor.name}',
    );
  }

  Future<void> _activateCounselor(
    AdminCounselorModel counselor,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      title: 'Activate Counselor',
      message: 'Activate ${counselor.name} as an active counselor?',
      confirmText: 'Activate',
      confirmColor: AppColors.success,
    );

    if (!confirmed) return;

    await _runStatusAction(
      counselor: counselor,
      action: () => _counselorService.approveCounselor(counselor.id),
      successMessage: '${counselor.name} berhasil diaktifkan.',
      activity: 'Admin activated counselor: ${counselor.name}',
    );
  }

  Future<void> _suspendCounselor(
    AdminCounselorModel counselor,
  ) async {
    final bool confirmed = await _showConfirmationDialog(
      title: 'Suspend Counselor',
      message:
          'Suspend ${counselor.name}? Counselor tidak dapat menggunakan akun sementara.',
      confirmText: 'Suspend',
      confirmColor: AppColors.error,
    );

    if (!confirmed) return;

    await _runStatusAction(
      counselor: counselor,
      action: () => _counselorService.suspendCounselor(counselor.id),
      successMessage: '${counselor.name} berhasil ditangguhkan.',
      activity: 'Admin suspended counselor: ${counselor.name}',
    );
  }

  Future<void> _runStatusAction({
    required AdminCounselorModel counselor,
    required Future<void> Function() action,
    required String successMessage,
    required String activity,
  }) async {
    if (_processingCounselorId != null) return;

    setState(() {
      _processingCounselorId = counselor.id;
    });

    try {
      await action();

      if (!mounted) return;

      context.read<AppState>().addAdminActivity(activity);
      _showMessage(successMessage, isError: false);
      await _loadCounselors(showLoading: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _cleanErrorMessage(error.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingCounselorId = null;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
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

  String _cleanErrorMessage(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }

  String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final DateTime localDate = date.toLocal();
    return '${months[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
  }

  String _formatDateTime(DateTime date) {
    final DateTime localDate = date.toLocal();
    final String hour = localDate.hour.toString().padLeft(2, '0');
    final String minute = localDate.minute.toString().padLeft(2, '0');
    return '${_formatDate(localDate)} • $hour:$minute';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showAddCounselorDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Add Counselor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminCounselorsBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        _loadCounselors(showLoading: false),
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
        children: [
          Expanded(
            child: Text(
              'Counselor Management',
              style: GoogleFonts.poppins(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadCounselors,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white.withOpacity(0.92),
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
        children: const [
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
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load counselors',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadCounselors,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Text(
          'Manage counselor approval, profile, and account status.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatistics(),
        const SizedBox(height: 18),
        _buildSearchAndFilter(),
        const SizedBox(height: 18),
        if (_filteredCounselors.isEmpty)
          _buildEmptyState()
        else
          ..._filteredCounselors.map(_buildCounselorCard),
      ],
    );
  }

  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.22,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatBox(
          title: 'Total Counselors',
          value: '$_totalCounselors',
          icon: Icons.medical_services_rounded,
          color: AppColors.brandBlue,
        ),
        _StatBox(
          title: 'Active',
          value: '$_activeCounselors',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        _StatBox(
          title: 'Inactive',
          value: '$_inactiveCounselors',
          icon: Icons.remove_circle_rounded,
          color: AppColors.textMedium,
        ),
        _StatBox(
          title: 'Pending',
          value: '$_pendingCounselors',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFD68A1F),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
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
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search name, email, specialty...',
              hintStyle: GoogleFonts.poppins(fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
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
                  selected: _selectedStatus == 'all',
                  onTap: () => setState(() => _selectedStatus = 'all'),
                ),
                _FilterChipItem(
                  label: 'Pending',
                  selected: _selectedStatus == 'pending',
                  onTap: () => setState(() => _selectedStatus = 'pending'),
                ),
                _FilterChipItem(
                  label: 'Active',
                  selected: _selectedStatus == 'active',
                  onTap: () => setState(() => _selectedStatus = 'active'),
                ),
                _FilterChipItem(
                  label: 'Inactive',
                  selected: _selectedStatus == 'inactive',
                  onTap: () => setState(() => _selectedStatus = 'inactive'),
                ),
                _FilterChipItem(
                  label: 'Suspended',
                  selected: _selectedStatus == 'suspended',
                  onTap: () => setState(() => _selectedStatus = 'suspended'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorCard(AdminCounselorModel counselor) {
    final bool isProcessing = _processingCounselorId == counselor.id;

    return Container(
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
                radius: 23,
                backgroundColor: AppColors.secondaryLight,
                child: Icon(
                  Icons.medical_services_rounded,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counselor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      counselor.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: counselor.status),
            ],
          ),
          const SizedBox(height: 13),
          _informationRow(
            icon: Icons.psychology_outlined,
            text: counselor.specialization,
          ),
          const SizedBox(height: 7),
          _informationRow(
            icon: Icons.video_call_outlined,
            text: counselor.consultationType,
          ),
          const SizedBox(height: 7),
          _informationRow(
            icon: Icons.location_on_outlined,
            text: counselor.location,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 5),
              Text(
                _formatDate(counselor.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFF5A623),
              ),
              const SizedBox(width: 3),
              Text(
                counselor.rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            )
          else
            _buildActionButtons(counselor),
        ],
      ),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMedium),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AdminCounselorModel counselor) {
    if (counselor.status == 'pending') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCounselorDetail(counselor),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'View',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveCounselor(counselor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _rejectCounselor(counselor),
              child: Text(
                'Reject Application',
                style: GoogleFonts.poppins(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showCounselorDetail(counselor),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'View',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (counselor.status == 'inactive' ||
                  counselor.status == 'suspended') {
                _activateCounselor(counselor);
              } else {
                _setInactive(counselor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: counselor.status == 'active'
                  ? AppColors.error
                  : AppColors.success,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              counselor.status == 'active' ? 'Inactive' : 'Activate',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          onSelected: (String value) {
            if (value == 'edit') {
              _showEditCounselorDialog(counselor);
            } else if (value == 'suspend') {
              _suspendCounselor(counselor);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (counselor.status == 'active')
              const PopupMenuItem<String>(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Suspend'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
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
            'No counselors found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another search or filter.',
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
}

class _AddCounselorDialog extends StatefulWidget {
  final CounselorService counselorService;

  const _AddCounselorDialog({required this.counselorService});

  @override
  State<_AddCounselorDialog> createState() => _AddCounselorDialogState();
}

class _AddCounselorDialogState extends State<_AddCounselorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _experienceController =
      TextEditingController(text: '0');
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _onlinePriceController =
      TextEditingController(text: '0');
  final TextEditingController _offlinePriceController =
      TextEditingController(text: '0');

  bool _offersOnline = true;
  bool _offersOffline = true;
  bool _hidePassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _onlinePriceController.dispose();
    _offlinePriceController.dispose();
    super.dispose();
  }

  Future<void> _saveCounselor() async {
    FocusScope.of(context).unfocus();

    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_offersOnline && !_offersOffline) {
      setState(() {
        _errorMessage = 'Pilih minimal satu jenis konsultasi.';
      });
      return;
    }

    final int yearsExperience =
        int.tryParse(_experienceController.text.trim()) ?? 0;
    final double onlinePrice =
        double.tryParse(_onlinePriceController.text.trim()) ?? 0;
    final double offlinePrice =
        double.tryParse(_offlinePriceController.text.trim()) ?? 0;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.counselorService.createCounselor(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        specialization: _specializationController.text.trim(),
        yearsExperience: yearsExperience,
        location: _locationController.text.trim(),
        professionalBio: _bioController.text.trim(),
        offersOnline: _offersOnline,
        offersOffline: _offersOffline,
        priceOnline: onlinePrice,
        priceOffline: offlinePrice,
      );

      if (!mounted) return;
      Navigator.of(context).pop(_fullNameController.text.trim());
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      });
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    final String name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required';
    if (name.length < 3) return 'Minimum 3 characters';
    return null;
  }

  String? _validateUsername(String? value) {
    final String username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username is required';
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username)) {
      return 'Use 3–30 letters, numbers, or underscore';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateInteger(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Value is required';
    final int? number = int.tryParse(text);
    if (number == null) return 'Enter a valid number';
    if (number < 0) return 'Value cannot be negative';
    return null;
  }

  String? _validatePrice(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';
    final double? number = double.tryParse(text);
    if (number == null) return 'Enter a valid price';
    if (number < 0) return 'Price cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add Counselor',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  _DialogErrorBox(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                _buildField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  validator: _validateFullName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: _validateUsername,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _passwordController,
                  label: 'Temporary Password',
                  validator: _validatePassword,
                  obscureText: _hidePassword,
                  suffixIcon: IconButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _specializationController,
                  label: 'Specialization',
                  validator: (value) =>
                      _validateRequired(value, 'Specialization'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _experienceController,
                  label: 'Years of Experience',
                  keyboardType: TextInputType.number,
                  validator: _validateInteger,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _locationController,
                  label: 'Location',
                  validator: (value) => _validateRequired(value, 'Location'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _bioController,
                  label: 'Professional Bio',
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                _buildSwitch(
                  title: 'Online Consultation',
                  subtitle: 'Counselor provides online sessions.',
                  value: _offersOnline,
                  onChanged: (value) {
                    setState(() {
                      _offersOnline = value;
                    });
                  },
                ),
                if (_offersOnline) ...[
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _onlinePriceController,
                    label: 'Online Price',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validatePrice,
                  ),
                ],
                const SizedBox(height: 10),
                _buildSwitch(
                  title: 'Offline Consultation',
                  subtitle: 'Counselor provides face-to-face sessions.',
                  value: _offersOffline,
                  onChanged: (value) {
                    setState(() {
                      _offersOffline = value;
                    });
                  },
                ),
                if (_offersOffline) ...[
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _offlinePriceController,
                    label: 'Offline Price',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validatePrice,
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Akun counselor akan dibuat dengan status Pending. '
                    'Setelah itu admin perlu menekan Approve.',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AppColors.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCounselor,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  'Create Counselor',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textMedium,
          ),
        ),
        value: value,
        activeColor: AppColors.primary,
        onChanged: _isSaving ? null : onChanged,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: AppColors.textDark,
      ),
      decoration: _inputDecoration(label, suffixIcon: suffixIcon),
    );
  }
}

class _EditCounselorDialog extends StatefulWidget {
  final AdminCounselorModel counselor;
  final CounselorService counselorService;

  const _EditCounselorDialog({
    required this.counselor,
    required this.counselorService,
  });

  @override
  State<_EditCounselorDialog> createState() =>
      _EditCounselorDialogState();
}

class _EditCounselorDialogState extends State<_EditCounselorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _specializationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _onlinePriceController;
  late final TextEditingController _offlinePriceController;

  late bool _offersOnline;
  late bool _offersOffline;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final AdminCounselorModel counselor = widget.counselor;

    _nameController = TextEditingController(text: counselor.name);
    _specializationController = TextEditingController(
      text: counselor.specialization == 'Not specified'
          ? ''
          : counselor.specialization,
    );
    _experienceController =
        TextEditingController(text: counselor.yearsExperience.toString());
    _locationController = TextEditingController(
      text: counselor.location == 'Location not specified'
          ? ''
          : counselor.location,
    );
    _bioController = TextEditingController(text: counselor.bio);
    _onlinePriceController =
        TextEditingController(text: counselor.priceOnline.toStringAsFixed(0));
    _offlinePriceController =
        TextEditingController(text: counselor.priceOffline.toStringAsFixed(0));

    _offersOnline = counselor.offersOnline;
    _offersOffline = counselor.offersOffline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _onlinePriceController.dispose();
    _offlinePriceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_offersOnline && !_offersOffline) {
      setState(() {
        _errorMessage = 'Pilih minimal satu jenis konsultasi.';
      });
      return;
    }

    final int yearsExperience =
        int.tryParse(_experienceController.text.trim()) ?? 0;
    final double priceOnline =
        double.tryParse(_onlinePriceController.text.trim()) ?? 0;
    final double priceOffline =
        double.tryParse(_offlinePriceController.text.trim()) ?? 0;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.counselorService.updateCounselorProfile(
        counselorId: widget.counselor.id,
        fullName: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
        yearsExperience: yearsExperience,
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        offersOnline: _offersOnline,
        offersOffline: _offersOffline,
        priceOnline: priceOnline,
        priceOffline: priceOffline,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      });
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Years of experience is required';
    }
    final int? result = int.tryParse(value.trim());
    if (result == null) return 'Enter a valid number';
    if (result < 0) return 'Value cannot be negative';
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final double? result = double.tryParse(value.trim());
    if (result == null) return 'Enter a valid price';
    if (result < 0) return 'Price cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'Edit Counselor',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  _DialogErrorBox(message: _errorMessage!),
                  const SizedBox(height: 14),
                ],
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      _validateRequired(value, 'Full name'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _specializationController,
                  label: 'Specialization',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      _validateRequired(value, 'Specialization'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _experienceController,
                  label: 'Years of Experience',
                  keyboardType: TextInputType.number,
                  validator: _validateInteger,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _locationController,
                  label: 'Location',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, 'Location'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _onlinePriceController,
                  label: 'Online Price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _offlinePriceController,
                  label: 'Offline Price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _bioController,
                  label: 'Professional Bio',
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                _buildSwitch(
                  title: 'Online Consultation',
                  subtitle: 'Counselor provides online sessions.',
                  value: _offersOnline,
                  onChanged: (value) {
                    setState(() {
                      _offersOnline = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildSwitch(
                  title: 'Offline Consultation',
                  subtitle: 'Counselor provides offline sessions.',
                  value: _offersOffline,
                  onChanged: (value) {
                    setState(() {
                      _offersOffline = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AppColors.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textMedium,
          ),
        ),
        value: value,
        activeColor: AppColors.primary,
        onChanged: _isSaving ? null : onChanged,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: AppColors.textDark,
      ),
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.textMedium,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.primarySoft,
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
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 1.5,
      ),
    ),
  );
}

class _DialogErrorBox extends StatelessWidget {
  final String message;

  const _DialogErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.error,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final String label;

    switch (status) {
      case 'active':
        label = 'Active';
        break;
      case 'inactive':
        label = 'Inactive';
        break;
      case 'pending':
        label = 'Pending';
        break;
      case 'suspended':
        label = 'Suspended';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(status),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _textColor(status),
        ),
      ),
    );
  }

  Color _backgroundColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFDFF7EB);
      case 'pending':
        return const Color(0xFFFFF0D9);
      case 'suspended':
        return const Color(0xFFFFE1E1);
      case 'inactive':
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  Color _textColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF1F9D62);
      case 'pending':
        return const Color(0xFFD68A1F);
      case 'suspended':
        return AppColors.error;
      case 'inactive':
      default:
        return const Color(0xFF777777);
    }
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            fontSize: 11,
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

class _AdminCounselorsBackground extends StatelessWidget {
  const _AdminCounselorsBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _AdminCounselorsBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminCounselorsBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminCounselorsBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _AdminCounselorsBlob(
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

class _AdminCounselorsBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminCounselorsBlob({
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
