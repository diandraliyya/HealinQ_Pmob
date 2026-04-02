import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class AdminCounselorsScreen extends StatefulWidget {
  const AdminCounselorsScreen({super.key});

  @override
  State<AdminCounselorsScreen> createState() => _AdminCounselorsScreenState();
}

class _AdminCounselorsScreenState extends State<AdminCounselorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_AdminCounselorItem> _counselors = [
    _AdminCounselorItem(
      id: 1,
      name: 'Dr. Aulia Rahman',
      email: 'aulia@healinq.com',
      specialty: 'Anxiety',
      address: 'Jakarta, Indonesia',
      joined: 'Mar 28, 2026',
      status: 'Active',
      sessions: 128,
    ),
    _AdminCounselorItem(
      id: 2,
      name: 'Dr. Nabila Putri',
      email: 'nabila@healinq.com',
      specialty: 'Self-Esteem',
      address: 'Bandung, Indonesia',
      joined: 'Mar 27, 2026',
      status: 'Active',
      sessions: 114,
    ),
    _AdminCounselorItem(
      id: 3,
      name: 'Dr. Farhan Yusuf',
      email: 'farhan@healinq.com',
      specialty: 'Trauma',
      address: 'Surabaya, Indonesia',
      joined: 'Mar 26, 2026',
      status: 'Inactive',
      sessions: 102,
    ),
    _AdminCounselorItem(
      id: 4,
      name: 'Dr. Keisha Amanda',
      email: 'keisha@healinq.com',
      specialty: 'Depression',
      address: 'Yogyakarta, Indonesia',
      joined: 'Mar 25, 2026',
      status: 'Active',
      sessions: 96,
    ),
    _AdminCounselorItem(
      id: 5,
      name: 'Dr. Rafi Pradana',
      email: 'rafi@healinq.com',
      specialty: 'Stress',
      address: 'Medan, Indonesia',
      joined: 'Mar 24, 2026',
      status: 'Pending',
      sessions: 0,
    ),
    _AdminCounselorItem(
      id: 6,
      name: 'Dr. Salma Nadhira',
      email: 'salma@healinq.com',
      specialty: 'Relationships',
      address: 'Semarang, Indonesia',
      joined: 'Mar 23, 2026',
      status: 'Active',
      sessions: 87,
    ),
  ];

  String _selectedStatus = 'All';

  List<_AdminCounselorItem> get _filteredCounselors {
    final query = _searchController.text.trim().toLowerCase();

    return _counselors.where((counselor) {
      final matchesSearch =
          counselor.name.toLowerCase().contains(query) ||
          counselor.email.toLowerCase().contains(query) ||
          counselor.address.toLowerCase().contains(query) ||
          counselor.specialty.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ? true : counselor.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalCounselors => _counselors.length;
  int get _activeCounselors =>
      _counselors.where((e) => e.status == 'Active').length;
  int get _inactiveCounselors =>
      _counselors.where((e) => e.status == 'Inactive').length;
  int get _pendingCounselors =>
      _counselors.where((e) => e.status == 'Pending').length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCounselorDetail(_AdminCounselorItem counselor) {
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
                  'Counselor Detail',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _detailTile('Name', counselor.name),
                _detailTile('Email', counselor.email),
                _detailTile('Specialty', counselor.specialty),
                _detailTile('Address', counselor.address),
                _detailTile('Joined', counselor.joined),
                _detailTile('Sessions', '${counselor.sessions}'),
                _detailTile('Status', counselor.status),
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

  void _showAddCounselorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final specialtyController = TextEditingController();
    final addressController = TextEditingController();
    final sessionsController = TextEditingController(text: '0');
    String status = 'Pending';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Add Counselor',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameController, 'Full name'),
                    const SizedBox(height: 10),
                    _dialogField(emailController, 'Email'),
                    const SizedBox(height: 10),
                    _dialogField(specialtyController, 'Specialty'),
                    const SizedBox(height: 10),
                    _dialogField(addressController, 'Address'),
                    const SizedBox(height: 10),
                    _dialogField(
                      sessionsController,
                      'Sessions',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => status = value);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primarySoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: AppColors.textMedium),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        specialtyController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    final counselorName = nameController.text.trim();

                    setState(() {
                      _counselors.insert(
                        0,
                        _AdminCounselorItem(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: counselorName,
                          email: emailController.text.trim(),
                          specialty: specialtyController.text.trim(),
                          address: addressController.text.trim(),
                          joined: 'Today',
                          status: status,
                          sessions:
                              int.tryParse(sessionsController.text.trim()) ?? 0,
                        ),
                      );
                    });

                    context.read<AppState>().addAdminActivity(
                      'Admin added new counselor: $counselorName',
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Counselor added successfully'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCounselorDialog(_AdminCounselorItem counselor) {
    final nameController = TextEditingController(text: counselor.name);
    final emailController = TextEditingController(text: counselor.email);
    final specialtyController = TextEditingController(text: counselor.specialty);
    final addressController = TextEditingController(text: counselor.address);
    final sessionsController =
        TextEditingController(text: counselor.sessions.toString());
    String status = counselor.status;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Edit Counselor',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameController, 'Full name'),
                    const SizedBox(height: 10),
                    _dialogField(emailController, 'Email'),
                    const SizedBox(height: 10),
                    _dialogField(specialtyController, 'Specialty'),
                    const SizedBox(height: 10),
                    _dialogField(addressController, 'Address'),
                    const SizedBox(height: 10),
                    _dialogField(
                      sessionsController,
                      'Sessions',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => status = value);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primarySoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: AppColors.textMedium),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        specialtyController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    final index =
                        _counselors.indexWhere((item) => item.id == counselor.id);
                    if (index == -1) return;

                    final updatedName = nameController.text.trim();

                    setState(() {
                      _counselors[index] = _AdminCounselorItem(
                        id: counselor.id,
                        name: updatedName,
                        email: emailController.text.trim(),
                        specialty: specialtyController.text.trim(),
                        address: addressController.text.trim(),
                        joined: counselor.joined,
                        status: status,
                        sessions:
                            int.tryParse(sessionsController.text.trim()) ?? 0,
                      );
                    });

                    context.read<AppState>().addAdminActivity(
                      'Admin edited counselor: $updatedName',
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Counselor updated successfully'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13),
        filled: true,
        fillColor: AppColors.primarySoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFFDFF7EB);
      case 'Inactive':
        return const Color(0xFFF3F3F3);
      case 'Pending':
        return const Color(0xFFFFF0D9);
      default:
        return AppColors.primarySoft;
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF1F9D62);
      case 'Inactive':
        return const Color(0xFF7B7B7B);
      case 'Pending':
        return const Color(0xFFD68A1F);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCounselorDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Add Counselor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        color: AppColors.bgGradientStart,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AdminCounselorsBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Counselor Management',
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      children: [
                        Text(
                          'Manage counselor accounts, specialties, and status details',
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
                                      'Search counselor, email, specialty...',
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
                                      label: 'Active',
                                      selected: _selectedStatus == 'Active',
                                      onTap: () => setState(
                                        () => _selectedStatus = 'Active',
                                      ),
                                    ),
                                    _FilterChipItem(
                                      label: 'Inactive',
                                      selected: _selectedStatus == 'Inactive',
                                      onTap: () => setState(
                                        () => _selectedStatus = 'Inactive',
                                      ),
                                    ),
                                    _FilterChipItem(
                                      label: 'Pending',
                                      selected: _selectedStatus == 'Pending',
                                      onTap: () => setState(
                                        () => _selectedStatus = 'Pending',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ..._filteredCounselors.map(
                          (counselor) => Container(
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
                                      backgroundColor:
                                          AppColors.secondaryLight,
                                      child: Icon(
                                        Icons.medical_services_rounded,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            counselor.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusBg(counselor.status),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        counselor.status,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusText(counselor.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.psychology_outlined,
                                      size: 16,
                                      color: AppColors.textMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        counselor.specialty,
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
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.textMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        counselor.address,
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
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: AppColors.textMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      counselor.joined,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${counselor.sessions} sessions',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showCounselorDetail(counselor),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
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
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showEditCounselorDialog(counselor),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Edit',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
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
                        if (_filteredCounselors.isEmpty)
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
                                  'No counselors found',
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
      ),
    );
  }
}

class _AdminCounselorItem {
  final int id;
  final String name;
  final String email;
  final String specialty;
  final String address;
  final String joined;
  final String status;
  final int sessions;

  _AdminCounselorItem({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.address,
    required this.joined,
    required this.status,
    required this.sessions,
  });
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