import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_dashboard_screen.dart';
import '../counselor/counselor_dashboard_screen.dart';
import '../counselor/counselor_waiting_approval_screen.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  static const Color _baseColor = AppColors.bgGradientStart;
  static const Color _titleColor = AppColors.brandTeal;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    final bool isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> profile = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final String role =
          profile['role']?.toString().trim().toLowerCase() ?? '';

      final String status =
          profile['status']?.toString().trim().toLowerCase() ?? '';

      if (role.isEmpty) {
        await AuthService().logout();

        if (!mounted) return;

        _showErrorMessage(
          'Role akun tidak ditemukan. Silakan hubungi admin.',
        );
        return;
      }

      if (status == 'inactive') {
        await AuthService().logout();

        if (!mounted) return;

        _showErrorMessage(
          'Akun kamu sedang tidak aktif. Silakan hubungi admin.',
        );
        return;
      }

      if (status == 'suspended') {
        await AuthService().logout();

        if (!mounted) return;

        _showErrorMessage(
          'Akun kamu sedang ditangguhkan. Silakan hubungi admin.',
        );
        return;
      }

      Widget destination;

      if (role == 'counselor' && status == 'pending') {
        destination = const CounselorWaitingApprovalScreen();
      } else {
        if (status != 'active') {
          await AuthService().logout();

          if (!mounted) return;

          _showErrorMessage(
            'Status akun tidak valid. Silakan hubungi admin.',
          );
          return;
        }

        switch (role) {
          case 'admin':
            destination = const AdminDashboardScreen();
            break;

          case 'counselor':
            destination = const CounselorDashboardScreen();
            break;

          case 'user':
            destination = const HomeScreen();
            break;

          default:
            await AuthService().logout();

            if (!mounted) return;

            _showErrorMessage(
              'Jenis akun tidak dikenali. Silakan hubungi admin.',
            );
            return;
        }
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => destination,
        ),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showErrorMessage(
        _translateAuthError(error.message),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      await _safeLogout();

      if (!mounted) return;

      _showErrorMessage(
        _translateDatabaseError(error.message),
      );
    } catch (error) {
      if (!mounted) return;

      await _safeLogout();

      if (!mounted) return;

      _showErrorMessage(
        _cleanErrorMessage(error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _safeLogout() async {
    try {
      await AuthService().logout();
    } catch (_) {
      // Tidak perlu menampilkan error tambahan saat pembersihan session.
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.white,
            ),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _translateAuthError(String message) {
    final String lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }

    if (lowerMessage.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan cek inbox email kamu.';
    }

    if (lowerMessage.contains('user not found')) {
      return 'Akun dengan email tersebut tidak ditemukan.';
    }

    if (lowerMessage.contains('too many requests') ||
        lowerMessage.contains('rate limit')) {
      return 'Terlalu banyak percobaan login. Silakan tunggu beberapa saat.';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('socket') ||
        lowerMessage.contains('connection')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet kamu.';
    }

    return message;
  }

  String _translateDatabaseError(String message) {
    final String lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('multiple') &&
        lowerMessage.contains('rows')) {
      return 'Data profil akun terduplikasi. Silakan hubungi admin.';
    }

    if (lowerMessage.contains('zero rows') ||
        lowerMessage.contains('no rows')) {
      return 'Profil akun tidak ditemukan di database.';
    }

    if (lowerMessage.contains('permission denied') ||
        lowerMessage.contains('row-level security')) {
      return 'Akses profil ditolak oleh database. Periksa pengaturan RLS.';
    }

    return 'Gagal membaca profil akun: $message';
  }

  String _cleanErrorMessage(String message) {
    String cleanMessage = message.trim();

    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring('Exception: '.length);
    }

    if (cleanMessage.isEmpty) {
      return 'Login gagal. Silakan coba kembali.';
    }

    return cleanMessage;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    final RegExp emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter your password';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  void _goToSignUp() {
    if (_isLoading) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _baseColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    22,
                    24,
                    20,
                  ),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 14),
                      Text(
                        'Continue where you left off.\nWe\'re here for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        32,
                        30,
                        32,
                        36,
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Sign in to continue to HealinQ',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              AppTextField(
                                hint: 'Email',
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                hint: 'Password',
                                controller: _passwordController,
                                isPassword: true,
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.brandTeal,
                                    foregroundColor:
                                        AppColors.white,
                                    disabledBackgroundColor:
                                        AppColors.brandTeal
                                            .withOpacity(0.55),
                                    disabledForegroundColor:
                                        AppColors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 21,
                                          height: 21,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.3,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Center(
                                child: GestureDetector(
                                  onTap: _goToSignUp,
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text:
                                          'Don\'t have an account? ',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textMedium,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: GoogleFonts.poppins(
                                            color:
                                                AppColors.brandTeal,
                                            fontWeight:
                                                FontWeight.w700,
                                            decoration:
                                                TextDecoration
                                                    .underline,
                                          ),
                                        ),
                                      ],
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo_healinq.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return const SizedBox(
          width: 100,
          height: 100,
        );
      },
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _LoginGradientBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _LoginGradientBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _LoginGradientBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.52,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
      ],
    );
  }
}

class _LoginGradientBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _LoginGradientBlob({
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