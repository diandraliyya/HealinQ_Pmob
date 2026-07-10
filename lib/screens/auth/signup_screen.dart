import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl =
      TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;

  static const Color _baseColor = AppColors.bgGradientStart;
  static const Color _titleColor = AppColors.brandTeal;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().signUpUser(
        fullName: _fullNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      final bool confirmationRequired =
          result['confirmation_required'] == true;

      final bool isCounselor =
          result['role']?.toString() == 'counselor';

      String successMessage;

      if (isCounselor && confirmationRequired) {
        successMessage =
            'Akun counselor berhasil dibuat. Silakan konfirmasi email, lalu tunggu persetujuan admin.';
      } else if (isCounselor) {
        successMessage =
            'Akun counselor berhasil dibuat. Silakan tunggu persetujuan admin sebelum menggunakan layanan counselor.';
      } else if (confirmationRequired) {
        successMessage =
            'Akun berhasil dibuat. Silakan konfirmasi email terlebih dahulu, lalu login.';
      } else {
        successMessage =
            'Akun berhasil dibuat. Silakan login menggunakan email dan password kamu.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showErrorMessage(
        _translateAuthError(error.message),
      );
    } catch (error) {
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _cleanErrorMessage(String message) {
    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('AuthException(message: ', '')
        .trim();
  }

  String _translateAuthError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('user already registered') ||
        lowerMessage.contains('already been registered')) {
      return 'Email tersebut sudah terdaftar. Silakan gunakan email lain atau login.';
    }

    if (lowerMessage.contains('email rate limit')) {
      return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat lalu coba kembali.';
    }

    if (lowerMessage.contains('password')) {
      return 'Password belum memenuhi ketentuan keamanan.';
    }

    if (lowerMessage.contains('invalid email')) {
      return 'Format email tidak valid.';
    }

    if (lowerMessage.contains('database error saving new user')) {
      return 'Akun gagal disimpan ke database. Periksa trigger profil di Supabase.';
    }

    return message;
  }

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Full name is required';
    }

    if (name.length < 3) {
      return 'Full name must be at least 3 characters';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (username.length > 30) {
      return 'Username cannot exceed 30 characters';
    }

    final usernameRegex = RegExp(
      r'^[a-zA-Z0-9_]+$',
    );

    if (!usernameRegex.hasMatch(username)) {
      return 'Use only letters, numbers, and underscore';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordCtrl.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void _goToLogin() {
    if (_isLoading) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _baseColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SignupBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    20,
                  ),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 14),
                      Text(
                        'Create your safe space.\nYour journey starts here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 19,
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
                        28,
                        32,
                        36,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
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
                                'Create an account to continue',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),

                            AppTextField(
                              hint: 'Full Name',
                              controller: _fullNameCtrl,
                              validator: _validateFullName,
                            ),
                            const SizedBox(height: 14),

                            AppTextField(
                              hint: 'Username',
                              controller: _usernameCtrl,
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 14),

                            AppTextField(
                              hint: 'Email',
                              controller: _emailCtrl,
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),

                            AppTextField(
                              hint: 'Password',
                              controller: _passwordCtrl,
                              isPassword: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 14),

                            AppTextField(
                              hint: 'Confirm Password',
                              controller: _confirmPasswordCtrl,
                              isPassword: true,
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 22),

                            Text(
                              'Register As',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: _AccountTypeCard(
                                    title: 'User',
                                    subtitle:
                                        'Use journals, FYP, and consultation.',
                                    icon: Icons.person_rounded,
                                    selected:
                                        _selectedRole == 'user',
                                    onTap: () {
                                      setState(() {
                                        _selectedRole = 'user';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AccountTypeCard(
                                    title: 'Counselor',
                                    subtitle:
                                        'Requires approval from admin.',
                                    icon:
                                        Icons.psychology_rounded,
                                    selected:
                                        _selectedRole ==
                                            'counselor',
                                    onTap: () {
                                      setState(() {
                                        _selectedRole =
                                            'counselor';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            if (_selectedRole == 'counselor') ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.20),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Akun counselor akan berstatus pending dan baru dapat digunakan setelah disetujui oleh admin.',
                                        style:
                                            GoogleFonts.poppins(
                                          fontSize: 11,
                                          color:
                                              AppColors.textMedium,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _signUp,
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
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style:
                                            GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Center(
                              child: GestureDetector(
                                onTap: _goToLogin,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text:
                                        'Already have an account? ',
                                    style: GoogleFonts.poppins(
                                      color:
                                          AppColors.textMedium,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
                                        style:
                                            GoogleFonts.poppins(
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
      width: 90,
      height: 90,
      fit: BoxFit.contain,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return const SizedBox(
          width: 90,
          height: 90,
        );
      },
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.title,
    required this.subtitle,
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
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(
            minHeight: 145,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySoft
                : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceBorder,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          AppColors.primary.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? AppColors.white
                          : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: -3,
                      top: -3,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.success,
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: AppColors.textMedium,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupBackground extends StatelessWidget {
  const _SignupBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _SignupGradientBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _SignupGradientBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _SignupGradientBlob(
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

class _SignupGradientBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _SignupGradientBlob({
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