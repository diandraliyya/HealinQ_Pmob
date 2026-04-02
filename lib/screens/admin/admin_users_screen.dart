import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<_AdminUserItem> _users = [
    _AdminUserItem(
      id: 1,
      name: 'Alya Putri',
      email: 'alya@gmail.com',
      address: 'Jakarta, Indonesia',
      joined: 'Mar 28, 2026',
      status: 'Active',
    ),
    _AdminUserItem(
      id: 2,
      name: 'Nadhif Ramadhan',
      email: 'nadhif@gmail.com',
      address: 'Bandung, Indonesia',
      joined: 'Mar 27, 2026',
      status: 'Active',
    ),
    _AdminUserItem(
      id: 3,
      name: 'Citra Maharani',
      email: 'citra@gmail.com',
      address: 'Surabaya, Indonesia',
      joined: 'Mar 26, 2026',
      status: 'Inactive',
    ),
    _AdminUserItem(
      id: 4,
      name: 'Raka Pratama',
      email: 'raka@gmail.com',
      address: 'Yogyakarta, Indonesia',
      joined: 'Mar 25, 2026',
      status: 'Active',
    ),
    _AdminUserItem(
      id: 5,
      name: 'Salwa Nabila',
      email: 'salwa@gmail.com',
      address: 'Medan, Indonesia',
      joined: 'Mar 24, 2026',
      status: 'Suspended',
    ),
    _AdminUserItem(
      id: 6,
      name: 'Kevin Saputra',
      email: 'kevin@gmail.com',
      address: 'Semarang, Indonesia',
      joined: 'Mar 23, 2026',
      status: 'Active',
    ),
  ];

  final List<Map<String, String>> _lyrics = [
    {
      'title': 'Who Knows',
      'artist': 'Daniel Caesar',
      'lyric':
          'You\'re pure, you\'re kind, mature, divine. You might be too good for me.',
    },
    {
      'title': 'Fight Song',
      'artist': 'Rachel Platten',
      'lyric':
          'This is my fight song, take back my life song, prove I\'m alright song.',
    },
    {
      'title': 'Rise Up',
      'artist': 'Andra Day',
      'lyric': 'And I\'ll rise up, I\'ll rise like the day.',
    },
  ];

  final List<Map<String, String>> _jarItems = [
    {
      'type': 'affirmation',
      'content': 'Kamu sudah melakukan yang terbaik hari ini! 🌟',
    },
    {
      'type': 'question',
      'content': 'Apa 3 hal yang kamu syukuri hari ini?',
    },
    {
      'type': 'challenge',
      'content': 'Challenge: Minum 8 gelas air hari ini! 💧',
    },
  ];

  final List<Map<String, String>> _fypQuestions = [
    {
      'question':
          'Seberapa sering Anda menikmati membantu orang lain yang membutuhkan?',
    },
    {
      'question':
          'Seberapa sering Anda menikmati belajar hal-hal baru tentang teknologi?',
    },
    {
      'question':
          'Seberapa sering Anda menikmati membuat karya seni atau kreatif?',
    },
  ];

  String _selectedStatus = 'All';

  List<_AdminUserItem> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.address.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ? true : user.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalUsers => _users.length;
  int get _activeUsers => _users.where((e) => e.status == 'Active').length;
  int get _inactiveUsers => _users.where((e) => e.status == 'Inactive').length;
  int get _suspendedUsers =>
      _users.where((e) => e.status == 'Suspended').length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showUserDetail(_AdminUserItem user) {
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
                  'User Detail',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _detailTile('Name', user.name),
                _detailTile('Email', user.email),
                _detailTile('Address', user.address),
                _detailTile('Joined', user.joined),
                _detailTile('Status', user.status),
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

  void _showEditUserDialog(_AdminUserItem user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address);
    String status = user.status;

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
                'Edit User',
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
                    _dialogField(addressController, 'Address'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Inactive', child: Text('Inactive')),
                        DropdownMenuItem(
                          value: 'Suspended',
                          child: Text('Suspended'),
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
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    final index =
                        _users.indexWhere((item) => item.id == user.id);
                    if (index == -1) return;

                    setState(() {
                      _users[index] = _AdminUserItem(
                        id: user.id,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        address: addressController.text.trim(),
                        joined: user.joined,
                        status: status,
                      );
                    });

                    context.read<AppState>().addAdminActivity(
                          'Admin edited user: ${nameController.text.trim()}',
                        );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
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

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String status = 'Active';

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
                'Add User',
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
                    _dialogField(addressController, 'Address'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: 'Suspended',
                          child: Text('Suspended'),
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
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      _users.insert(
                        0,
                        _AdminUserItem(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          address: addressController.text.trim(),
                          joined: 'Today',
                          status: status,
                        ),
                      );
                    });

                    context.read<AppState>().addAdminActivity(
                          'Admin added new user: ${nameController.text.trim()}',
                        );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User added successfully'),
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

  void _showAddLyricDialog() {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    final lyricController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Add Lyric',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(titleController, 'Song title'),
              const SizedBox(height: 10),
              _dialogField(artistController, 'Artist'),
              const SizedBox(height: 10),
              _dialogField(lyricController, 'Lyric', maxLines: 4),
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
              if (titleController.text.trim().isEmpty ||
                  artistController.text.trim().isEmpty ||
                  lyricController.text.trim().isEmpty) {
                return;
              }

              setState(() {
                _lyrics.insert(0, {
                  'title': titleController.text.trim(),
                  'artist': artistController.text.trim(),
                  'lyric': lyricController.text.trim(),
                });
              });

              context.read<AppState>().addAdminActivity(
                    'Admin added new lyric: ${titleController.text.trim()}',
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lyric added successfully')),
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
      ),
    );
  }

  void _showAddJarDialog() {
    final contentController = TextEditingController();
    String selectedType = 'affirmation';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Add Jar Item',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'affirmation',
                      child: Text('Affirmation'),
                    ),
                    DropdownMenuItem(
                      value: 'question',
                      child: Text('Question'),
                    ),
                    DropdownMenuItem(
                      value: 'challenge',
                      child: Text('Challenge'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => selectedType = value);
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
                const SizedBox(height: 10),
                _dialogField(contentController, 'Content', maxLines: 4),
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
                if (contentController.text.trim().isEmpty) return;

                setState(() {
                  _jarItems.insert(0, {
                    'type': selectedType,
                    'content': contentController.text.trim(),
                  });
                });

                context.read<AppState>().addAdminActivity(
                      'Admin added jar item',
                    );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jar item added successfully')),
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
        ),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Add FYP Question',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: _dialogField(questionController, 'Question', maxLines: 4),
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
              if (questionController.text.trim().isEmpty) return;

              setState(() {
                _fypQuestions.insert(0, {
                  'question': questionController.text.trim(),
                });
              });

              context.read<AppState>().addAdminActivity(
                    'Admin added new FYP question',
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question added successfully')),
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
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
      case 'Suspended':
        return const Color(0xFFFFE1EA);
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
      case 'Suspended':
        return const Color(0xFFD64B7F);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildStatBox({
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

  Widget _buildUsersTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatBox(
              title: 'Total Users',
              value: '$_totalUsers',
              icon: Icons.people_rounded,
              color: AppColors.brandBlue,
            ),
            _buildStatBox(
              title: 'Active Users',
              value: '$_activeUsers',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _buildStatBox(
              title: 'Inactive',
              value: '$_inactiveUsers',
              icon: Icons.remove_circle_rounded,
              color: AppColors.textMedium,
            ),
            _buildStatBox(
              title: 'Suspended',
              value: '$_suspendedUsers',
              icon: Icons.block_rounded,
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
                  hintText: 'Search user, email, or address...',
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
                      onTap: () => setState(() => _selectedStatus = 'All'),
                    ),
                    _FilterChipItem(
                      label: 'Active',
                      selected: _selectedStatus == 'Active',
                      onTap: () => setState(() => _selectedStatus = 'Active'),
                    ),
                    _FilterChipItem(
                      label: 'Inactive',
                      selected: _selectedStatus == 'Inactive',
                      onTap: () => setState(() => _selectedStatus = 'Inactive'),
                    ),
                    _FilterChipItem(
                      label: 'Suspended',
                      selected: _selectedStatus == 'Suspended',
                      onTap: () =>
                          setState(() => _selectedStatus = 'Suspended'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ..._filteredUsers.map(
          (user) => Container(
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
                        Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
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
                        color: _statusBg(user.status),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        user.status,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusText(user.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        user.address,
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
                      user.joined,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showUserDetail(user),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEditUserDialog(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
        if (_filteredUsers.isEmpty)
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
                  'No users found',
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
    );
  }

  Widget _buildLyricsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatBox(
              title: 'Total Lyrics',
              value: '${_lyrics.length}',
              icon: Icons.music_note_rounded,
              color: AppColors.primary,
            ),
            _buildStatBox(
              title: 'Today Active',
              value: _lyrics.isNotEmpty ? '1' : '0',
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.brandBlue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._lyrics.asMap().entries.map((entry) {
          final index = entry.key;
          final lyric = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lyric['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _lyrics.removeAt(index));

                        context.read<AppState>().addAdminActivity(
                              'Admin deleted a lyric',
                            );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Text(
                  lyric['artist'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lyric['lyric'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJarTab() {
    final totalAffirmations =
        _jarItems.where((e) => e['type'] == 'affirmation').length;

    final totalQuestions =
        _jarItems.where((e) => e['type'] == 'question').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatBox(
              title: 'Total Jar Items',
              value: '${_jarItems.length}',
              icon: Icons.favorite_rounded,
              color: AppColors.primary,
            ),
            _buildStatBox(
              title: 'Challenges',
              value:
                  '${_jarItems.where((e) => e['type'] == 'challenge').length}',
              icon: Icons.flag_rounded,
              color: AppColors.brandBlue,
            ),
          ],
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
            _buildStatBox(
              title: 'Affirmations',
              value:
                  '${_jarItems.where((e) => e['type'] == 'affirmation').length}',
              icon: Icons.favorite_rounded,
              color: AppColors.primary,
            ),
            _buildStatBox(
              title: 'Questions',
              value:
                  '${_jarItems.where((e) => e['type'] == 'question').length}',
              icon: Icons.help_outline_rounded,
              color: AppColors.brandBlue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._jarItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    item['type'] == 'affirmation'
                        ? Icons.favorite_rounded
                        : item['type'] == 'question'
                            ? Icons.help_outline_rounded
                            : Icons.flag_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['type'] ?? '').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['content'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _jarItems.removeAt(index));
                    context.read<AppState>().addAdminActivity(
                          'Admin deleted jar item',
                        );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFypTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SizedBox(
          height: 150,
          child: _buildStatBox(
            title: 'Total Questions',
            value: '${_fypQuestions.length}',
            icon: Icons.psychology_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ..._fypQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['question'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.45,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _fypQuestions.removeAt(index));
                    context.read<AppState>().addAdminActivity(
                          'Admin deleted FYP question',
                        );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: _showAddUserDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(
            'Add User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: _showAddLyricDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Lyric',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _showAddJarDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Jar Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: _showAddQuestionDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Question',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      floatingActionButton: _buildFab(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminUsersBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Users & User Content',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Manage user accounts, lyric of the day, jar of happiness, and FYP questions',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.primary,
                    dividerColor: Colors.transparent,
                    isScrollable: false,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Users'),
                      Tab(text: 'Lyrics'),
                      Tab(text: 'Jar'),
                      Tab(text: 'FYP'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersTab(),
                      _buildLyricsTab(),
                      _buildJarTab(),
                      _buildFypTab(),
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

class _AdminUserItem {
  final int id;
  final String name;
  final String email;
  final String address;
  final String joined;
  final String status;

  _AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.joined,
    required this.status,
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

class _AdminUsersBackground extends StatelessWidget {
  const _AdminUsersBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _AdminUsersBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _AdminUsersBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _AdminUsersBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _AdminUsersBlob(
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

class _AdminUsersBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _AdminUsersBlob({
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
