import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class CounselorScheduleScreen extends StatefulWidget {
  const CounselorScheduleScreen({super.key});

  @override
  State<CounselorScheduleScreen> createState() =>
      _CounselorScheduleScreenState();
}

class _CounselorScheduleScreenState extends State<CounselorScheduleScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<_CounselorSlot> _slots = <_CounselorSlot>[];

  String _counselorName = 'Counselor';
  String _accountStatus = '';
  String _selectedFilter = 'available';

  bool _offersOnline = true;
  bool _offersOffline = true;
  bool _isLoading = true;
  bool _isMutating = false;

  String? _errorMessage;
  String? _processingSlotId;

  User? get _currentUser => _supabase.auth.currentUser;

  bool get _canManageSchedule => _accountStatus == 'active';

  List<_CounselorSlot> get _visibleSlots {
    final DateTime now = DateTime.now();

    final List<_CounselorSlot> filtered = _slots.where((_CounselorSlot slot) {
      switch (_selectedFilter) {
        case 'available':
          return slot.status == 'available' && slot.startAt.isAfter(now);
        case 'booked':
          return slot.status == 'booked' && slot.endAt.isAfter(now);
        case 'past':
          return !slot.endAt.isAfter(now);
        case 'all':
        default:
          return true;
      }
    }).toList();

    filtered.sort(
      (_CounselorSlot first, _CounselorSlot second) =>
          first.startAt.compareTo(second.startAt),
    );

    return filtered;
  }

  int get _availableCount {
    final DateTime now = DateTime.now();

    return _slots
        .where(
          (_CounselorSlot slot) =>
              slot.status == 'available' && slot.startAt.isAfter(now),
        )
        .length;
  }

  int get _bookedCount {
    final DateTime now = DateTime.now();

    return _slots
        .where(
          (_CounselorSlot slot) =>
              slot.status == 'booked' && slot.endAt.isAfter(now),
        )
        .length;
  }

  int get _todayCount {
    final DateTime now = DateTime.now();

    return _slots.where((_CounselorSlot slot) {
      return slot.startAt.year == now.year &&
          slot.startAt.month == now.month &&
          slot.startAt.day == now.day;
    }).length;
  }

  bool get _isAvailable {
    final DateTime now = DateTime.now();

    return _slots.any(
      (_CounselorSlot slot) =>
          slot.status == 'available' && slot.startAt.isAfter(now),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final User? user = _currentUser;

      if (user == null) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      final Map<String, dynamic> profile =
          Map<String, dynamic>.from(
        await _supabase
            .from('profiles')
            .select('id, full_name, role, status')
            .eq('id', user.id)
            .single(),
      );

      if (profile['role']?.toString() != 'counselor') {
        throw Exception(
          'Halaman ini hanya dapat diakses oleh counselor.',
        );
      }

      final Map<String, dynamic> counselorProfile =
          Map<String, dynamic>.from(
        await _supabase
            .from('counselor_profiles')
            .select(
              'id, offers_online, offers_offline, is_available',
            )
            .eq('id', user.id)
            .single(),
      );

      final List<dynamic> rawSlots = await _supabase
          .from('counselor_slots')
          .select(
            'id, counselor_id, consultation_type, '
            'start_at, end_at, status, created_at, updated_at',
          )
          .eq('counselor_id', user.id)
          .order('start_at', ascending: true);

      final List<_CounselorSlot> slots = rawSlots
          .map(
            (dynamic item) => _CounselorSlot.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _counselorName =
            profile['full_name']?.toString().trim().isNotEmpty == true
                ? profile['full_name'].toString().trim()
                : 'Counselor';
        _accountStatus = profile['status']?.toString() ?? '';
        _offersOnline = counselorProfile['offers_online'] == true;
        _offersOffline = counselorProfile['offers_offline'] == true;
        _slots = slots;
        _errorMessage = null;
      });

      await _syncAvailabilityQuietly();
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _translatePostgrestError(error);
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

  Future<void> _syncAvailabilityQuietly() async {
    final User? user = _currentUser;

    if (user == null || _accountStatus != 'active') {
      return;
    }

    try {
      await _supabase
          .from('counselor_profiles')
          .update(<String, dynamic>{
            'is_available': _isAvailable,
          })
          .eq('id', user.id);
    } catch (_) {
      // Slot tetap berhasil tersimpan meskipun sinkronisasi indikator
      // availability mengalami kendala sementara.
    }
  }

  Future<void> _openAddSlot() async {
    if (_isMutating) return;

    if (!_canManageSchedule) {
      _showMessage(
        'Akun counselor harus berstatus active sebelum membuat jadwal.',
        isError: true,
      );
      return;
    }

    if (!_offersOnline && !_offersOffline) {
      _showMessage(
        'Aktifkan minimal satu jenis konsultasi melalui halaman Profile.',
        isError: true,
      );
      return;
    }

    final _SlotFormResult? result =
        await showModalBottomSheet<_SlotFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _SlotFormSheet(
          offersOnline: _offersOnline,
          offersOffline: _offersOffline,
        );
      },
    );

    if (!mounted || result == null) return;

    await _createSlot(result);
  }

  Future<void> _createSlot(
    _SlotFormResult result,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Sesi login tidak ditemukan.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isMutating = true;
    });

    try {
      await _supabase.from('counselor_slots').insert(
        <String, dynamic>{
          'counselor_id': user.id,
          'consultation_type': result.consultationType,
          'start_at': result.startAt.toUtc().toIso8601String(),
          'end_at': result.endAt.toUtc().toIso8601String(),
          'status': 'available',
        },
      );

      await _loadSchedule(showLoading: false);

      if (!mounted) return;

      _showMessage(
        'Jadwal konsultasi berhasil ditambahkan.',
        isError: false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      _showMessage(
        _translatePostgrestError(error),
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanErrorMessage(error.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _openEditSlot(
    _CounselorSlot slot,
  ) async {
    if (_isMutating || !slot.canBeModified) return;

    final _SlotFormResult? result =
        await showModalBottomSheet<_SlotFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _SlotFormSheet(
          offersOnline: _offersOnline,
          offersOffline: _offersOffline,
          initialSlot: slot,
        );
      },
    );

    if (!mounted || result == null) return;

    await _updateSlot(slot, result);
  }

  Future<void> _updateSlot(
    _CounselorSlot slot,
    _SlotFormResult result,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Sesi login tidak ditemukan.',
        isError: true,
      );
      return;
    }

    setState(() {
      _processingSlotId = slot.id;
      _isMutating = true;
    });

    try {
      final List<dynamic> updatedRows = await _supabase
          .from('counselor_slots')
          .update(<String, dynamic>{
            'consultation_type': result.consultationType,
            'start_at': result.startAt.toUtc().toIso8601String(),
            'end_at': result.endAt.toUtc().toIso8601String(),
          })
          .eq('id', slot.id)
          .eq('counselor_id', user.id)
          .eq('status', 'available')
          .select('id');

      if (updatedRows.isEmpty) {
        throw Exception(
          'Slot sudah berubah atau tidak lagi tersedia untuk diedit.',
        );
      }

      await _loadSchedule(showLoading: false);

      if (!mounted) return;

      _showMessage(
        'Jadwal konsultasi berhasil diperbarui.',
        isError: false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      _showMessage(
        _translatePostgrestError(error),
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanErrorMessage(error.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingSlotId = null;
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteSlot(
    _CounselorSlot slot,
  ) async {
    if (_isMutating || !slot.canBeModified) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete Schedule',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Hapus jadwal ${_formatFullDate(slot.startAt)} '
            'pukul ${_formatTime(slot.startAt)}–'
            '${_formatTime(slot.endAt)}?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await _deleteSlot(slot);
  }

  Future<void> _deleteSlot(
    _CounselorSlot slot,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Sesi login tidak ditemukan.',
        isError: true,
      );
      return;
    }

    setState(() {
      _processingSlotId = slot.id;
      _isMutating = true;
    });

    try {
      final List<dynamic> deletedRows = await _supabase
          .from('counselor_slots')
          .delete()
          .eq('id', slot.id)
          .eq('counselor_id', user.id)
          .eq('status', 'available')
          .select('id');

      if (deletedRows.isEmpty) {
        throw Exception(
          'Slot sudah berubah atau tidak lagi tersedia untuk dihapus.',
        );
      }

      await _loadSchedule(showLoading: false);

      if (!mounted) return;

      _showMessage(
        'Jadwal berhasil dihapus.',
        isError: false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      _showMessage(
        _translatePostgrestError(error),
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanErrorMessage(error.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingSlotId = null;
          _isMutating = false;
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
          backgroundColor:
              isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _translatePostgrestError(
    PostgrestException error,
  ) {
    final String combined =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();

    if (combined.contains('23p01') ||
        combined.contains('counselor_slots_no_overlap') ||
        combined.contains('conflicting key value violates exclusion')) {
      return 'Jadwal bertabrakan dengan slot lain yang sudah tersedia '
          'atau sudah dibooking.';
    }

    if (combined.contains('row-level security') ||
        combined.contains('42501') ||
        combined.contains('permission denied')) {
      return 'Kamu tidak memiliki izin untuk mengubah jadwal ini. '
          'Pastikan akun counselor sudah active.';
    }

    if (combined.contains('end_at') &&
        combined.contains('start_at')) {
      return 'Jam selesai harus lebih lambat dari jam mulai.';
    }

    if (combined.contains('foreign key')) {
      return 'Profil counselor belum tersedia atau tidak valid.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan saat mengelola jadwal.'
        : error.message.trim();
  }

  String _cleanErrorMessage(String message) {
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('PostgrestException(message: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _ScheduleBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () {
                      return _loadSchedule(
                        showLoading: false,
                      );
                    },
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
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atur slot konsultasi berdasarkan tanggal dan jam.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isMutating
                ? null
                : () {
                    _loadSchedule();
                  },
            style: IconButton.styleFrom(
              backgroundColor:
                  AppColors.white.withOpacity(0.92),
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
        physics:
            const AlwaysScrollableScrollPhysics(),
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
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 70),
          Container(
            padding: const EdgeInsets.all(22),
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
                  'Failed to load schedule',
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
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadSchedule,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        104,
      ),
      children: <Widget>[
        _buildAvailabilityCard(),
        const SizedBox(height: 14),
        _buildStatistics(),
        const SizedBox(height: 20),
        if (!_canManageSchedule) ...<Widget>[
          _buildInactiveBanner(),
          const SizedBox(height: 18),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Consultation Slots',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  _canManageSchedule && !_isMutating
                      ? _openAddSlot
                      : null,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: Text(
                'Add Slot',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.textLight.withOpacity(0.2),
                disabledForegroundColor:
                    AppColors.textMedium,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Slot booked tidak dapat diedit atau dihapus.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 12),
        _buildFilter(),
        const SizedBox(height: 14),
        if (_visibleSlots.isEmpty)
          _buildEmptyState()
        else
          ..._visibleSlots.map(
            (_CounselorSlot slot) =>
                _buildSlotCard(slot),
          ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: _isAvailable
                ? AppColors.success.withOpacity(0.12)
                : AppColors.textLight.withOpacity(0.16),
            child: Icon(
              _isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              color: _isAvailable
                  ? AppColors.success
                  : AppColors.textMedium,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _counselorName,
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
                  _isAvailable
                      ? 'Available — memiliki slot yang dapat dibooking.'
                      : 'Not available — belum ada slot tersedia.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    height: 1.5,
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
              color: _isAvailable
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _isAvailable ? 'Available' : 'Offline',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isAvailable
                    ? AppColors.success
                    : AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ScheduleStatCard(
            title: 'Available',
            value: '$_availableCount',
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScheduleStatCard(
            title: 'Booked',
            value: '$_bookedCount',
            icon: Icons.event_busy_rounded,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScheduleStatCard(
            title: 'Today',
            value: '$_todayCount',
            icon: Icons.today_rounded,
            color: AppColors.brandBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Status akunmu saat ini '
              '${_accountStatus.isEmpty ? 'tidak diketahui' : _accountStatus}. '
              'Hanya counselor active yang dapat menambah atau '
              'mengubah jadwal.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.error,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _ScheduleFilterChip(
            label: 'Available',
            count: _availableCount,
            selected:
                _selectedFilter == 'available',
            onTap: () {
              setState(() {
                _selectedFilter = 'available';
              });
            },
          ),
          _ScheduleFilterChip(
            label: 'Booked',
            count: _bookedCount,
            selected: _selectedFilter == 'booked',
            onTap: () {
              setState(() {
                _selectedFilter = 'booked';
              });
            },
          ),
          _ScheduleFilterChip(
            label: 'Past',
            selected: _selectedFilter == 'past',
            onTap: () {
              setState(() {
                _selectedFilter = 'past';
              });
            },
          ),
          _ScheduleFilterChip(
            label: 'All',
            count: _slots.length,
            selected: _selectedFilter == 'all',
            onTap: () {
              setState(() {
                _selectedFilter = 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(
    _CounselorSlot slot,
  ) {
    final bool isProcessing =
        _processingSlotId == slot.id;
    final bool isPast =
        !slot.endAt.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _statusColor(slot.status)
              .withOpacity(0.16),
        ),
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
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    _typeColor(slot.consultationType)
                        .withOpacity(0.12),
                child: Icon(
                  slot.consultationType == 'online'
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  color: _typeColor(
                    slot.consultationType,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _formatFullDate(slot.startAt),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatTime(slot.startAt)} – '
                      '${_formatTime(slot.endAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _SlotStatusBadge(
                status: isPast ? 'past' : slot.status,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              _SlotInfoBadge(
                icon:
                    slot.consultationType == 'online'
                        ? Icons.language_rounded
                        : Icons.meeting_room_rounded,
                text: slot.consultationType == 'online'
                    ? 'Online'
                    : 'Offline',
                color: _typeColor(
                  slot.consultationType,
                ),
              ),
              const SizedBox(width: 8),
              _SlotInfoBadge(
                icon: Icons.timelapse_rounded,
                text:
                    '${slot.durationMinutes} minutes',
                color: AppColors.textMedium,
              ),
              const Spacer(),
              if (isProcessing)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (slot.canBeModified &&
                  _canManageSchedule)
                PopupMenuButton<String>(
                  tooltip: 'Schedule actions',
                  onSelected: (String value) {
                    if (value == 'edit') {
                      _openEditSlot(slot);
                    }

                    if (value == 'delete') {
                      _confirmDeleteSlot(slot);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) =>
                          const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 19,
                  color: AppColors.textLight,
                ),
            ],
          ),
          if (slot.status == 'booked' &&
              !isPast) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color:
                    AppColors.teal.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Text(
                'Slot ini sudah dibooking dan tidak dapat diubah.',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.teal,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;

    switch (_selectedFilter) {
      case 'available':
        message =
            'Belum ada slot tersedia. Tambahkan jadwal agar user dapat melakukan booking.';
        break;
      case 'booked':
        message =
            'Belum ada slot yang dibooking.';
        break;
      case 'past':
        message =
            'Belum ada riwayat slot yang telah lewat.';
        break;
      default:
        message =
            'Belum ada jadwal konsultasi.';
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.event_note_rounded,
            size: 50,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No schedule found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          if (_selectedFilter == 'available' &&
              _canManageSchedule) ...<Widget>[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  _isMutating ? null : _openAddSlot,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text('Add First Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    return type == 'online'
        ? AppColors.brandBlue
        : AppColors.teal;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.success;
      case 'booked':
        return AppColors.teal;
      case 'blocked':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }
}

class _SlotFormSheet extends StatefulWidget {
  final bool offersOnline;
  final bool offersOffline;
  final _CounselorSlot? initialSlot;

  const _SlotFormSheet({
    required this.offersOnline,
    required this.offersOffline,
    this.initialSlot,
  });

  @override
  State<_SlotFormSheet> createState() =>
      _SlotFormSheetState();
}

class _SlotFormSheetState
    extends State<_SlotFormSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _consultationType;

  String? _errorMessage;

  bool get _isEditing =>
      widget.initialSlot != null;

  @override
  void initState() {
    super.initState();

    final _CounselorSlot? initial =
        widget.initialSlot;

    if (initial != null) {
      _selectedDate = DateTime(
        initial.startAt.year,
        initial.startAt.month,
        initial.startAt.day,
      );
      _startTime = TimeOfDay.fromDateTime(
        initial.startAt,
      );
      _endTime = TimeOfDay.fromDateTime(
        initial.endAt,
      );
      _consultationType =
          initial.consultationType;
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime initialDate =
        now.hour >= 20
            ? now.add(const Duration(days: 1))
            : now;

    _selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    final int nextHour =
        now.minute == 0 ? now.hour + 1 : now.hour + 2;
    final int safeHour =
        nextHour.clamp(8, 20).toInt();

    _startTime = TimeOfDay(
      hour: safeHour,
      minute: 0,
    );
    _endTime = TimeOfDay(
      hour: (safeHour + 1).clamp(9, 23).toInt(),
      minute: 0,
    );

    _consultationType = widget.offersOnline
        ? 'online'
        : 'offline';
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final DateTime lastDate = firstDate.add(
      const Duration(days: 365),
    );

    final DateTime initialDate =
        _selectedDate.isBefore(firstDate)
            ? firstDate
            : _selectedDate.isAfter(lastDate)
                ? lastDate
                : _selectedDate;

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select consultation date',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedDate = selected;
      _errorMessage = null;
    });
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Select start time',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _startTime = selected;
      _errorMessage = null;

      final int startMinutes =
          selected.hour * 60 + selected.minute;
      final int endMinutes =
          _endTime.hour * 60 + _endTime.minute;

      if (endMinutes <= startMinutes) {
        final int newEnd =
            (startMinutes + 60).clamp(0, 1439);

        _endTime = TimeOfDay(
          hour: newEnd ~/ 60,
          minute: newEnd % 60,
        );
      }
    });
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Select end time',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _endTime = selected;
      _errorMessage = null;
    });
  }

  void _submit() {
    final DateTime startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final DateTime endAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!startAt.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage =
            'Tanggal dan jam mulai harus berada di masa depan.';
      });
      return;
    }

    if (!endAt.isAfter(startAt)) {
      setState(() {
        _errorMessage =
            'Jam selesai harus lebih lambat dari jam mulai.';
      });
      return;
    }

    if (endAt.difference(startAt).inMinutes < 15) {
      setState(() {
        _errorMessage =
            'Durasi konsultasi minimal 15 menit.';
      });
      return;
    }

    if (_consultationType == 'online' &&
        !widget.offersOnline) {
      setState(() {
        _errorMessage =
            'Layanan konsultasi online belum diaktifkan di Profile.';
      });
      return;
    }

    if (_consultationType == 'offline' &&
        !widget.offersOffline) {
      setState(() {
        _errorMessage =
            'Layanan konsultasi offline belum diaktifkan di Profile.';
      });
      return;
    }

    Navigator.of(context).pop(
      _SlotFormResult(
        consultationType: _consultationType,
        startAt: startAt,
        endAt: endAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + keyboardHeight,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textLight
                        .withOpacity(0.4),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.primarySoft,
                    child: Icon(
                      _isEditing
                          ? Icons.edit_calendar_rounded
                          : Icons.add_task_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _isEditing
                              ? 'Edit Consultation Slot'
                              : 'Add Consultation Slot',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Pilih tanggal, waktu, dan jenis konsultasi.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color:
                                AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        AppColors.error.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error
                          .withOpacity(0.22),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.error,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Consultation Type',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  if (widget.offersOnline)
                    Expanded(
                      child: _TypeOption(
                        title: 'Online',
                        icon: Icons.videocam_rounded,
                        selected:
                            _consultationType == 'online',
                        onTap: () {
                          setState(() {
                            _consultationType =
                                'online';
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                  if (widget.offersOnline &&
                      widget.offersOffline)
                    const SizedBox(width: 10),
                  if (widget.offersOffline)
                    Expanded(
                      child: _TypeOption(
                        title: 'Offline',
                        icon:
                            Icons.location_on_rounded,
                        selected:
                            _consultationType == 'offline',
                        onTap: () {
                          setState(() {
                            _consultationType =
                                'offline';
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _PickerField(
                label: 'Date',
                value: _formatFullDate(
                  _selectedDate,
                ),
                icon:
                    Icons.calendar_month_rounded,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _PickerField(
                      label: 'Start Time',
                      value:
                          _formatTimeOfDay(_startTime),
                      icon: Icons.access_time_rounded,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerField(
                      label: 'End Time',
                      value:
                          _formatTimeOfDay(_endTime),
                      icon:
                          Icons.schedule_send_rounded,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Database akan menolak slot yang bertabrakan '
                        'dengan jadwal lain.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:
                              AppColors.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.textMedium,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(
                        _isEditing
                            ? Icons.save_rounded
                            : Icons.add_rounded,
                      ),
                      label: Text(
                        _isEditing
                            ? 'Save Changes'
                            : 'Create Slot',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            AppColors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.white
                    : AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.white
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: AppColors.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color:
                            AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
      height: 112,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleFilterChip
    extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final String text =
        count == null ? label : '$label ($count)';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.white
                : AppColors.primary,
          ),
        ),
        selected: selected,
        onSelected: (_) {
          onTap();
        },
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

class _SlotStatusBadge extends StatelessWidget {
  final String status;

  const _SlotStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    switch (status) {
      case 'available':
        label = 'Available';
        color = AppColors.success;
        break;
      case 'booked':
        label = 'Booked';
        color = AppColors.teal;
        break;
      case 'blocked':
        label = 'Blocked';
        color = AppColors.error;
        break;
      case 'past':
        label = 'Past';
        color = AppColors.textMedium;
        break;
      default:
        label = status;
        color = AppColors.textMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SlotInfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SlotInfoBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotFormResult {
  final String consultationType;
  final DateTime startAt;
  final DateTime endAt;

  const _SlotFormResult({
    required this.consultationType,
    required this.startAt,
    required this.endAt,
  });
}

class _CounselorSlot {
  final String id;
  final String counselorId;
  final String consultationType;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _CounselorSlot({
    required this.id,
    required this.counselorId,
    required this.consultationType,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory _CounselorSlot.fromMap(
    Map<String, dynamic> map,
  ) {
    return _CounselorSlot(
      id: map['id']?.toString() ?? '',
      counselorId:
          map['counselor_id']?.toString() ?? '',
      consultationType:
          map['consultation_type']?.toString() ??
              'online',
      startAt:
          DateTime.parse(map['start_at'].toString())
              .toLocal(),
      endAt: DateTime.parse(map['end_at'].toString())
          .toLocal(),
      status:
          map['status']?.toString() ?? 'available',
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(
              map['created_at'].toString(),
            ).toLocal(),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(
              map['updated_at'].toString(),
            ).toLocal(),
    );
  }

  bool get canBeModified {
    return status == 'available' &&
        startAt.isAfter(DateTime.now());
  }

  int get durationMinutes {
    return endAt.difference(startAt).inMinutes;
  }
}

String _formatFullDate(DateTime date) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final DateTime localDate = date.toLocal();

  return '${weekdays[localDate.weekday - 1]}, '
      '${localDate.day} '
      '${months[localDate.month - 1]} '
      '${localDate.year}';
}

String _formatTime(DateTime date) {
  final DateTime localDate = date.toLocal();

  final String hour =
      localDate.hour.toString().padLeft(2, '0');
  final String minute =
      localDate.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _formatTimeOfDay(TimeOfDay time) {
  final String hour =
      time.hour.toString().padLeft(2, '0');
  final String minute =
      time.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

class _ScheduleBackground extends StatelessWidget {
  const _ScheduleBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
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
    final Size size =
        MediaQuery.of(context).size;

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
