import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/admin_activity_model.dart';
import '../../services/admin_activity_service.dart';
import '../../theme/app_theme.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  static const int _rowsPerPage = 12;

  final AdminActivityService _service = AdminActivityService();

  final TextEditingController _searchController = TextEditingController();

  List<AdminActivityModel> _activities = <AdminActivityModel>[];

  String _selectedStatus = 'all';
  String _selectedCategory = 'all';

  String? _errorMessage;

  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<AdminActivityModel> result = await _service.getActivities();

      if (!mounted) return;

      setState(() {
        _activities = result;
        _currentPage = 1;
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

  List<String> get _categories {
    final List<String> result = _activities
        .map(
          (AdminActivityModel item) => item.category,
        )
        .where(
          (String value) => value.trim().isNotEmpty,
        )
        .toSet()
        .toList();

    result.sort();

    return result;
  }

  List<AdminActivityModel> get _filteredActivities {
    final String query = _searchController.text.trim().toLowerCase();

    final List<AdminActivityModel> result = _activities.where(
      (AdminActivityModel activity) {
        final bool matchesSearch = query.isEmpty ||
            activity.actorName.toLowerCase().contains(query) ||
            activity.action.toLowerCase().contains(query) ||
            activity.category.toLowerCase().contains(query) ||
            activity.actorRole.toLowerCase().contains(query) ||
            activity.description.toLowerCase().contains(query);

        final bool matchesStatus =
            _selectedStatus == 'all' || activity.status == _selectedStatus;

        final bool matchesCategory = _selectedCategory == 'all' ||
            activity.category == _selectedCategory;

        return matchesSearch && matchesStatus && matchesCategory;
      },
    ).toList();

    result.sort(
      (
        AdminActivityModel first,
        AdminActivityModel second,
      ) {
        return second.createdAt.compareTo(
          first.createdAt,
        );
      },
    );

    return result;
  }

  int get _totalPages {
    if (_filteredActivities.isEmpty) {
      return 1;
    }

    return (_filteredActivities.length / _rowsPerPage).ceil();
  }

  List<AdminActivityModel> get _paginatedActivities {
    final List<AdminActivityModel> source = _filteredActivities;

    final int page = _currentPage.clamp(1, _totalPages);

    final int start = (page - 1) * _rowsPerPage;

    if (start >= source.length) {
      return <AdminActivityModel>[];
    }

    final int end = (start + _rowsPerPage).clamp(
      0,
      source.length,
    );

    return source.sublist(start, end);
  }

  int get _completedActivities => _activities
      .where(
        (AdminActivityModel item) => item.status == 'completed',
      )
      .length;

  int get _pendingActivities => _activities
      .where(
        (AdminActivityModel item) => item.status == 'pending',
      )
      .length;

  int get _failedActivities => _activities
      .where(
        (AdminActivityModel item) => item.status == 'failed',
      )
      .length;

  void _resetPage() {
    setState(() {
      _currentPage = 1;
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'counselor':
        return 'Counselor';
      case 'user':
        return 'User';
      case 'system':
        return 'System';
      default:
        return role;
    }
  }

  Color _statusBackground(
    String status,
  ) {
    switch (status) {
      case 'completed':
        return const Color(0xFFDFF7EB);
      case 'pending':
        return const Color(0xFFFFF0D9);
      case 'failed':
        return const Color(0xFFFFE1EA);
      default:
        return AppColors.primarySoft;
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'completed':
        return const Color(0xFF1F9D62);
      case 'pending':
        return const Color(0xFFD68A1F);
      case 'failed':
        return const Color(0xFFD64B7F);
      default:
        return AppColors.primary;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'counselor':
        return Icons.medical_services_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _showActivityDetail(
    AdminActivityModel item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext sheetContext,
      ) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.48,
          maxChildSize: 0.94,
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
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  28,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  Text(
                    'Activity Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  _detailTile(
                    'Actor',
                    item.actorName,
                  ),
                  _detailTile(
                    'Role',
                    _roleLabel(
                      item.actorRole,
                    ),
                  ),
                  _detailTile(
                    'Action',
                    item.action,
                  ),
                  _detailTile(
                    'Category',
                    item.category,
                  ),
                  _detailTile(
                    'Description',
                    item.description.isEmpty ? '-' : item.description,
                  ),
                  _detailTile(
                    'Created At',
                    DateFormat(
                      'd MMMM yyyy, HH:mm:ss',
                    ).format(
                      item.createdAt,
                    ),
                  ),
                  _detailTile(
                    'Status',
                    _statusLabel(
                      item.status,
                    ),
                  ),
                  _detailTile(
                    'Target Type',
                    item.targetType ?? '-',
                  ),
                  _detailTile(
                    'Target ID',
                    item.targetId ?? '-',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          sheetContext,
                        ).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Close',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailTile(
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
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
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
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
          const _AdminActivityBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () {
                      return _loadActivities(
                        showLoading: false,
                      );
                    },
                    child: _buildBody(),
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
        8,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Activity Log',
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Pantau aktivitas administratif dan sistem.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadActivities,
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

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 230),
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
          _ErrorState(
            message: _errorMessage!,
            onRetry: _loadActivities,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        28,
      ),
      children: <Widget>[
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _statCard(
              title: 'Total Activities',
              value: '${_activities.length}',
              icon: Icons.history_rounded,
              color: AppColors.brandBlue,
            ),
            _statCard(
              title: 'Completed',
              value: '$_completedActivities',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _statCard(
              title: 'Pending',
              value: '$_pendingActivities',
              icon: Icons.hourglass_top_rounded,
              color: const Color(
                0xFFD68A1F,
              ),
            ),
            _statCard(
              title: 'Failed',
              value: '$_failedActivities',
              icon: Icons.error_rounded,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 14),
        if (_filteredActivities.isEmpty)
          const _EmptyState()
        else ...<Widget>[
          ..._paginatedActivities.map(
            _activityCard,
          ),
          _pagination(),
        ],
      ],
    );
  }

  Widget _buildFilters() {
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
            onChanged: (_) {
              _resetPage();
            },
            decoration: InputDecoration(
              hintText: 'Search actor, action, category, or description...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();

                        _resetPage();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _FilterChipItem(
                  label: 'All',
                  selected: _selectedStatus == 'all',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _currentPage = 1;
                    });
                  },
                ),
                _FilterChipItem(
                  label: 'Completed',
                  selected: _selectedStatus == 'completed',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'completed';
                      _currentPage = 1;
                    });
                  },
                ),
                _FilterChipItem(
                  label: 'Pending',
                  selected: _selectedStatus == 'pending',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'pending';
                      _currentPage = 1;
                    });
                  },
                ),
                _FilterChipItem(
                  label: 'Failed',
                  selected: _selectedStatus == 'failed',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'failed';
                      _currentPage = 1;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: 'all',
                child: Text(
                  'All Categories',
                ),
              ),
              ..._categories.map(
                (String category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              ),
            ],
            onChanged: (
              String? value,
            ) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedCategory = value;
                _currentPage = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _activityCard(
    AdminActivityModel item,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Icon(
                  _roleIcon(
                    item.actorRole,
                  ),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.actorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${_roleLabel(item.actorRole)} • ${item.category}',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(
                    item.status,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusLabel(
                    item.status,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(
                      item.status,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.action,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (item.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(
                    item.createdAt,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showActivityDetail(
                    item,
                  );
                },
                child: Text(
                  'View',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          Expanded(
            child: Text(
              'Page $_currentPage of $_totalPages • '
              '${_filteredActivities.length} activities',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
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
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          onTap();
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.primary,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No activities found',
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
}

class _ErrorState extends StatelessWidget {
  final String message;

  final Future<void> Function({
    bool showLoading,
  }) onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.error,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              onRetry(
                showLoading: true,
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _AdminActivityBackground extends StatelessWidget {
  const _AdminActivityBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _AdminActivityBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminActivityBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminActivityBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _AdminActivityBlob(
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

class _AdminActivityBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminActivityBlob({
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
                color.withOpacity(
                  opacity,
                ),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
