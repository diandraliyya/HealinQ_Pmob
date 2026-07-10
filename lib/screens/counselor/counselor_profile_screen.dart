import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_counselor_model.dart';
import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';

class CounselorProfileScreen extends StatefulWidget {
  const CounselorProfileScreen({super.key});

  @override
  State<CounselorProfileScreen> createState() =>
      _CounselorProfileScreenState();
}

class _CounselorProfileScreenState extends State<CounselorProfileScreen> {
  static const String _avatarBucket = 'profile-pictures';
  static const int _maximumAvatarSize = 2 * 1024 * 1024;

  final CounselorService _counselorService = CounselorService();
  final ImagePicker _imagePicker = ImagePicker();

  AdminCounselorModel? _counselor;
  String? _avatarPath;
  String? _avatarUrl;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final User? currentUser =
          Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'Sesi counselor tidak ditemukan. Silakan login kembali.',
        );
      }

      final AdminCounselorModel result =
          await _counselorService.getCounselorById(currentUser.id);

      final Map<String, dynamic> profileData =
          await Supabase.instance.client
              .from('profiles')
              .select('avatar_path')
              .eq('id', currentUser.id)
              .single();

      final String? avatarPath =
          profileData['avatar_path']?.toString().trim();

      if (!mounted) return;

      setState(() {
        _counselor = result;
        _avatarPath =
            avatarPath == null || avatarPath.isEmpty ? null : avatarPath;
        _avatarUrl = _buildAvatarUrl(_avatarPath);
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

  Future<void> _openEditProfile() async {
    final AdminCounselorModel? counselor = _counselor;

    if (counselor == null) return;

    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _EditCounselorProfileScreen(
          counselor: counselor,
          counselorService: _counselorService,
        ),
      ),
    );

    if (!mounted || updated != true) return;

    _showMessage(
      'Profil counselor berhasil diperbarui.',
      isError: false,
    );

    await _loadProfile(showLoading: false);
  }

  String? _buildAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return null;
    }

    final String publicUrl = Supabase.instance.client.storage
        .from(_avatarBucket)
        .getPublicUrl(avatarPath);

    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _showAvatarOptions() async {
    if (_isUploadingAvatar) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Picture',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih foto JPG, PNG, atau WEBP dengan ukuran maksimal 2 MB.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: AppColors.primarySoft,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    child: Icon(Icons.photo_library_rounded),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadAvatar();
                  },
                ),
                if (_avatarPath != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: AppColors.error.withOpacity(0.08),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      child: Icon(Icons.delete_outline_rounded),
                    ),
                    title: Text(
                      'Remove Current Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeAvatar();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (selectedImage == null || !mounted) return;

      final imageBytes = await selectedImage.readAsBytes();

      if (imageBytes.length > _maximumAvatarSize) {
        throw Exception(
          'Ukuran foto masih lebih dari 2 MB. Pilih foto yang lebih kecil.',
        );
      }

      final String extension = _fileExtension(selectedImage.name);
      final String contentType = _contentType(extension);

      final User? currentUser =
          Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'Sesi counselor tidak ditemukan. Silakan login kembali.',
        );
      }

      setState(() {
        _isUploadingAvatar = true;
      });

      final String newAvatarPath =
          '${currentUser.id}/avatar.$extension';
      final String? previousAvatarPath = _avatarPath;

      await Supabase.instance.client.storage
          .from(_avatarBucket)
          .uploadBinary(
            newAvatarPath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      await Supabase.instance.client
          .from('profiles')
          .update(<String, dynamic>{
            'avatar_path': newAvatarPath,
          })
          .eq('id', currentUser.id);

      if (previousAvatarPath != null &&
          previousAvatarPath != newAvatarPath) {
        try {
          await Supabase.instance.client.storage
              .from(_avatarBucket)
              .remove(<String>[previousAvatarPath]);
        } catch (_) {
          // Foto baru tetap valid meskipun file lama gagal dihapus.
        }
      }

      if (!mounted) return;

      setState(() {
        _avatarPath = newAvatarPath;
        _avatarUrl = _buildAvatarUrl(newAvatarPath);
      });

      _showMessage(
        'Foto profil berhasil diperbarui.',
        isError: false,
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
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_isUploadingAvatar || _avatarPath == null) return;

    final User? currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Sesi counselor tidak ditemukan. Silakan login kembali.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final String oldAvatarPath = _avatarPath!;

      await Supabase.instance.client
          .from('profiles')
          .update(<String, dynamic>{
            'avatar_path': null,
          })
          .eq('id', currentUser.id);

      try {
        await Supabase.instance.client.storage
            .from(_avatarBucket)
            .remove(<String>[oldAvatarPath]);
      } catch (_) {
        // Referensi database sudah dihapus; file lama dapat dibersihkan nanti.
      }

      if (!mounted) return;

      setState(() {
        _avatarPath = null;
        _avatarUrl = null;
      });

      _showMessage(
        'Foto profil berhasil dihapus.',
        isError: false,
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
          _isUploadingAvatar = false;
        });
      }
    }
  }

  String _fileExtension(String fileName) {
    final String lowerName = fileName.toLowerCase();
    final String extension = lowerName.contains('.')
        ? lowerName.split('.').last
        : 'jpg';

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      default:
        throw Exception(
          'Format foto tidak didukung. Gunakan JPG, PNG, atau WEBP.',
        );
    }
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final bool confirmed =
        await _showLogoutConfirmation();

    if (!confirmed || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService().logout();

      if (!mounted) return;

      context.read<AppState>().logout();

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (Route<dynamic> route) => false,
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
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari akun counselor?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              child: Text(
                'Logout',
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

  String _cleanErrorMessage(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _ProfileBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _loadProfile(showLoading: false),
              child: _buildContent(),
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
          SizedBox(height: 260),
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
          const SizedBox(height: 120),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: AppColors.error,
                ),
                const SizedBox(height: 14),
                Text(
                  'Gagal memuat profil',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
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
                    height: 1.5,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final AdminCounselorModel? counselor = _counselor;

    if (counselor == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: Text('Profil counselor tidak ditemukan.')),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildIdentityCard(counselor),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                title: 'Experience',
                value: '${counselor.yearsExperience} yrs',
                icon: Icons.work_history_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStatCard(
                title: 'Type',
                value: counselor.consultationType,
                icon: Icons.devices_rounded,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Account Information'),
        const SizedBox(height: 12),
        _InfoSection(
          children: [
            _InfoTile(
              icon: Icons.alternate_email_rounded,
              label: 'Username',
              value: counselor.username.isEmpty
                  ? '-'
                  : counselor.username,
            ),
            _InfoTile(
              icon: Icons.email_rounded,
              label: 'Email',
              value: counselor.email,
            ),
            _InfoTile(
              icon: Icons.verified_user_rounded,
              label: 'Account Status',
              value: counselor.statusLabel,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Counselor Information'),
        const SizedBox(height: 12),
        _InfoSection(
          children: [
            _InfoTile(
              icon: Icons.psychology_rounded,
              label: 'Specialization',
              value: counselor.specialization,
            ),
            _InfoTile(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: counselor.location,
            ),
            _InfoTile(
              icon: Icons.video_call_rounded,
              label: 'Online Price',
              value: counselor.offersOnline
                  ? _formatCurrency(counselor.priceOnline)
                  : 'Not offered',
            ),
            _InfoTile(
              icon: Icons.people_alt_rounded,
              label: 'Offline Price',
              value: counselor.offersOffline
                  ? _formatCurrency(counselor.priceOffline)
                  : 'Not offered',
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Professional Bio'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            counselor.bio.trim().isEmpty
                ? 'Bio belum diisi.'
                : counselor.bio,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openEditProfile,
            icon: const Icon(Icons.edit_rounded),
            label: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(
              _isLoggingOut ? 'Logging out...' : 'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola informasi profesional akun counselor.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => _loadProfile(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white.withOpacity(0.92),
          ),
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(AdminCounselorModel counselor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.secondaryLight,
                  backgroundImage: _avatarUrl == null
                      ? null
                      : NetworkImage(_avatarUrl!),
                  child: _avatarUrl == null
                      ? const Icon(
                          Icons.medical_services_rounded,
                          size: 56,
                          color: AppColors.teal,
                        )
                      : null,
                ),
              ),
              if (_isUploadingAvatar)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploadingAvatar
                        ? null
                        : _showAvatarOptions,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 19,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed:
                _isUploadingAvatar ? null : _showAvatarOptions,
            icon: const Icon(Icons.image_rounded, size: 18),
            label: Text(
              _avatarPath == null
                  ? 'Upload Profile Picture'
                  : 'Change Profile Picture',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            counselor.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            counselor.email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileBadge(
                icon: Icons.verified_rounded,
                text: counselor.isApproved
                    ? 'Approved'
                    : counselor.statusLabel,
                color: counselor.isApproved
                    ? AppColors.success
                    : AppColors.textMedium,
              ),
              _ProfileBadge(
                icon: Icons.circle_rounded,
                text: counselor.isAvailable
                    ? 'Available'
                    : 'Not Available',
                color: counselor.isAvailable
                    ? AppColors.success
                    : AppColors.textLight,
              ),
              _ProfileBadge(
                icon: Icons.star_rounded,
                text:
                    '${counselor.rating.toStringAsFixed(1)} Rating',
                color: AppColors.starYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
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

class _EditCounselorProfileScreen extends StatefulWidget {
  final AdminCounselorModel counselor;
  final CounselorService counselorService;

  const _EditCounselorProfileScreen({
    required this.counselor,
    required this.counselorService,
  });

  @override
  State<_EditCounselorProfileScreen> createState() =>
      _EditCounselorProfileScreenState();
}

class _EditCounselorProfileScreenState
    extends State<_EditCounselorProfileScreen> {
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
    _experienceController = TextEditingController(
      text: counselor.yearsExperience.toString(),
    );
    _locationController = TextEditingController(
      text: counselor.location == 'Location not specified'
          ? ''
          : counselor.location,
    );
    _bioController = TextEditingController(text: counselor.bio);
    _onlinePriceController = TextEditingController(
      text: counselor.priceOnline.toStringAsFixed(0),
    );
    _offlinePriceController = TextEditingController(
      text: counselor.priceOffline.toStringAsFixed(0),
    );

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

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_isSaving) return;

    final bool valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    if (!_offersOnline && !_offersOffline) {
      setState(() {
        _errorMessage =
            'Pilih minimal satu jenis konsultasi.';
      });
      return;
    }

    final int yearsExperience = int.tryParse(
          _experienceController.text.trim(),
        ) ??
        0;

    final double priceOnline = _offersOnline
        ? double.tryParse(_onlinePriceController.text.trim()) ?? 0
        : 0;

    final double priceOffline = _offersOffline
        ? double.tryParse(_offlinePriceController.text.trim()) ?? 0
        : 0;

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
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '').trim();
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
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Years of experience is required';
    }

    final int? number = int.tryParse(text);

    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return 'Value cannot be negative';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Price is required';
    }

    final double? number = double.tryParse(text);

    if (number == null) {
      return 'Enter a valid price';
    }

    if (number < 0) {
      return 'Price cannot be negative';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ProfileBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.secondaryLight,
                        child: Icon(
                          Icons.medical_services_rounded,
                          size: 50,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Username',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.counselor.username,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Email',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.counselor.email,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
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
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _EditField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.badge_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (String? value) {
                          return _validateRequired(value, 'Full name');
                        },
                      ),
                      const SizedBox(height: 16),
                      _EditField(
                        controller: _specializationController,
                        label: 'Specialization',
                        icon: Icons.psychology_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (String? value) {
                          return _validateRequired(
                            value,
                            'Specialization',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _EditField(
                        controller: _experienceController,
                        label: 'Years of Experience',
                        icon: Icons.work_history_rounded,
                        keyboardType: TextInputType.number,
                        validator: _validateInteger,
                      ),
                      const SizedBox(height: 16),
                      _EditField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (String? value) {
                          return _validateRequired(value, 'Location');
                        },
                      ),
                      const SizedBox(height: 16),
                      _EditField(
                        controller: _bioController,
                        label: 'Professional Bio',
                        icon: Icons.description_rounded,
                        maxLines: 4,
                        textCapitalization:
                            TextCapitalization.sentences,
                        validator: (String? value) {
                          return _validateRequired(value, 'Bio');
                        },
                      ),
                      const SizedBox(height: 18),
                      _ConsultationTypeCard(
                        title: 'Online Consultation',
                        subtitle:
                            'Aktifkan jika kamu menerima konsultasi online.',
                        value: _offersOnline,
                        enabled: !_isSaving,
                        onChanged: (bool value) {
                          setState(() {
                            _offersOnline = value;
                          });
                        },
                      ),
                      if (_offersOnline) ...[
                        const SizedBox(height: 12),
                        _EditField(
                          controller: _onlinePriceController,
                          label: 'Online Price',
                          icon: Icons.payments_rounded,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validatePrice,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _ConsultationTypeCard(
                        title: 'Offline Consultation',
                        subtitle:
                            'Aktifkan jika kamu menerima konsultasi tatap muka.',
                        value: _offersOffline,
                        enabled: !_isSaving,
                        onChanged: (bool value) {
                          setState(() {
                            _offersOffline = value;
                          });
                        },
                      ),
                      if (_offersOffline) ...[
                        const SizedBox(height: 12),
                        _EditField(
                          controller: _offlinePriceController,
                          label: 'Offline Price',
                          icon: Icons.payments_rounded,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validatePrice,
                        ),
                      ],
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : 'Save Changes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withOpacity(0.55),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ProfileBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 18,
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

class _InfoSection extends StatelessWidget {
  final List<Widget> children;

  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.surfaceBorder,
                  width: 0.7,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
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

class _ConsultationTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ConsultationTypeCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
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
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 7),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
                top: isMultiline ? 14 : 0,
                bottom: isMultiline ? 76 : 0,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 52,
              minHeight: 52,
            ),
            filled: true,
            fillColor: AppColors.primarySoft,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: isMultiline ? 18 : 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            errorStyle: GoogleFonts.poppins(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _ProfileBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _ProfileBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _ProfileBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _ProfileBlob(
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

class _ProfileBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _ProfileBlob({
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
