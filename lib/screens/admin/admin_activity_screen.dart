import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_ActivityItem> _activities = [
    _ActivityItem(
      id: 1,
      actor: 'Alya Putri',
      role: 'User',
      action: 'Created a new journal entry',
      category: 'Self-Healing',
      date: 'Mar 28, 2026',
      time: '09:15 AM',
      status: 'Completed',
      description:
          'The user created a new journal entry in the self-healing section.',
    ),
    _ActivityItem(
      id: 2,
      actor: 'Dr. Aulia Rahman',
      role: 'Counselor',
      action: 'Completed a counseling session',
      category: 'Consultation',
      date: 'Mar 28, 2026',
      time: '11:30 AM',
      status: 'Completed',
      description:
          'The counselor completed a scheduled counseling session with a user.',
    ),
    _ActivityItem(
      id: 3,
      actor: 'Admin',
      role: 'Admin',
      action: 'Updated counselor profile',
      category: 'Management',
      date: 'Mar 27, 2026',
      time: '02:40 PM',
      status: 'Completed',
      description:
          'The admin updated counselor information in the management panel.',
    ),
    _ActivityItem(
      id: 4,
      actor: 'Nadhif Ramadhan',
      role: 'User',
      action: 'Payment is still pending',
      category: 'Transactions',
      date: 'Mar 27, 2026',
      time: '04:10 PM',
      status: 'Pending',
      description:
          'The user payment transaction is pending verification.',
    ),
    _ActivityItem(
      id: 5,
      actor: 'System',
      role: 'System',
      action: 'Failed payment notification sent',
      category: 'Transactions',
      date: 'Mar 26, 2026',
      time: '08:20 PM',
      status: 'Failed',
      description:
          'The system sent a failed payment notification to the user.',
    ),
    _ActivityItem(
      id: 6,
      actor: 'Dr. Nabila Putri',
      role: 'Counselor',
      action: 'Updated availability schedule',
      category: 'Counselors',
      date: 'Mar 26, 2026',
      time: '01:00 PM',
      status: 'Completed',
      description:
          'The counselor updated weekly availability for future sessions.',
    ),
  ];

  String _selectedStatus = 'All';

  List<_ActivityItem> get _filteredActivities {
    final query = _searchController.text.trim().toLowerCase();

    return _activities.where((activity) {
      final matchesSearch =
          activity.actor.toLowerCase().contains(query) ||
          activity.action.toLowerCase().contains(query) ||
          activity.category.toLowerCase().contains(query) ||
          activity.role.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ? true : activity.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalActivities => _activities.length;
  int get _completedActivities =>
      _activities.where((e) => e.status == 'Completed').length;
  int get _pendingActivities =>
      _activities.where((e) => e.status == 'Pending').length;
  int get _failedActivities =>
      _activities.where((e) => e.status == 'Failed').length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFFDFF7EB);
      case 'Pending':
        return const Color(0xFFFFF0D9);
      case 'Failed':
        return const Color(0xFFFFE1EA);
      default:
        return AppColors.primarySoft;
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF1F9D62);
      case 'Pending':
        return const Color(0xFFD68A1F);
      case 'Failed':
        return const Color(0xFFD64B7F);
      default:
        return AppColors.primary;
    }
  }

  void _showActivityDetail(_ActivityItem item) {
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
                  'Activity Detail',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _detailTile('Actor', item.actor),
                _detailTile('Role', item.role),
                _detailTile('Action', item.action),
                _detailTile('Category', item.category),
                _detailTile('Description', item.description),
                _detailTile('Date', item.date),
                _detailTile('Time', item.time),
                _detailTile('Status', item.status),
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
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminActivityBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Activity Log',
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
                        'Monitor recent actions, updates, and platform events',
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
                            title: 'Total Activities',
                            value: '$_totalActivities',
                            icon: Icons.history_rounded,
                            color: AppColors.brandBlue,
                          ),
                          _buildStatCard(
                            title: 'Completed',
                            value: '$_completedActivities',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                          _buildStatCard(
                            title: 'Pending',
                            value: '$_pendingActivities',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFD68A1F),
                          ),
                          _buildStatCard(
                            title: 'Failed',
                            value: '$_failedActivities',
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
                                hintText: 'Search actor, action, or category...',
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
                                    label: 'Completed',
                                    selected: _selectedStatus == 'Completed',
                                    onTap: () => setState(
                                      () => _selectedStatus = 'Completed',
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
                      ..._filteredActivities.map(
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
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primarySoft,
                                    child: Icon(
                                      item.role == 'Admin'
                                          ? Icons.admin_panel_settings_rounded
                                          : item.role == 'Counselor'
                                              ? Icons.medical_services_rounded
                                              : item.role == 'System'
                                                  ? Icons.settings_rounded
                                                  : Icons.person,
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
                                          item.actor,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.role} • ${item.category}',
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
                                      color: _statusBg(item.status),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _statusText(item.status),
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
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textMedium,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
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
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppColors.textMedium,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.time,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _showActivityDetail(item),
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
                        ),
                      ),
                      if (_filteredActivities.isEmpty)
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
                                'No activities found',
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

class _ActivityItem {
  final int id;
  final String actor;
  final String role;
  final String action;
  final String category;
  final String date;
  final String time;
  final String status;
  final String description;

  _ActivityItem({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.category,
    required this.date,
    required this.time,
    required this.status,
    required this.description,
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

class _AdminActivityBackground extends StatelessWidget {
  const _AdminActivityBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
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