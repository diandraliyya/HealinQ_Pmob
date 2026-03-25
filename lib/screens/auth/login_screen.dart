import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  static const Color _baseColor = Color(0xFFD4EFFC);
  static const Color _titleColor = Color(0xFF4AA7A2);
  static const Color _subtitleColor = Color(0xFF4AA7A2);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final success = context.read<AppState>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _baseColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 18),
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
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      const Color.fromARGB(255, 12, 114, 166),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            AppTextField(
                              hint: 'Username/Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your email or username'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              hint: 'Password',
                              controller: _passwordController,
                              isPassword: true,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'or',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _login,
                                icon: const Icon(
                                  Icons.g_mobiledata,
                                  size: 24,
                                  color: Colors.blue,
                                ),
                                label: Text(
                                  'Login with Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4AA7A2),
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Don\'t have account? ',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textMedium,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF4AA7A2),
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
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
      width: 115,
      height: 115,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          width: 115,
          height: 115,
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
          color: Color(0xFFFFE5F4),
          opacity: 0.95,
        ),
        _LoginGradientBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: Color(0xFF53BAB3),
          opacity: 0.34,
        ),
        _LoginGradientBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.52,
          color: Color(0xFF9BDAF8),
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
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
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
    );
  }
}
