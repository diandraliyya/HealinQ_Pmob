import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Gradient Background Widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool isPink;

  const GradientBackground({super.key, required this.child, this.isPink = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPink
              ? [const Color(0xFFFCE4EC), const Color(0xFFE0F7FA)]
              : [const Color(0xFFB2EBF2), const Color(0xFFF8BBD9)],
        ),
      ),
      child: child,
    );
  }
}

// App Button
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double? width;
  final Color? color;

  const AppButton({
    super.key, required this.text, required this.onPressed,
    this.isPrimary = true, this.width, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? (isPrimary ? AppColors.teal : AppColors.primary),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// App Text Field
class AppTextField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  const AppTextField({
    super.key, required this.hint, this.isPassword = false,
    required this.controller, this.validator, this.keyboardType, this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: AppColors.textLight, size: 20) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textLight, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}

// Score/XP Card
class ScoreCard extends StatelessWidget {
  final int xp;
  const ScoreCard({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.starYellow, size: 18),
          const SizedBox(width: 4),
          Text('$xp', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// Counselor Card
class CounselorCard extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final VoidCallback onBook;
  final bool compact;

  const CounselorCard({
    super.key, required this.name, required this.specialization,
    required this.rating, required this.onBook, this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundColor: AppColors.secondaryLight, child: Icon(Icons.person, color: AppColors.teal, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(specialization, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMedium)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.starYellow, size: 16),
                  Text('$rating', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onBook,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
                  child: Text('Book', style: GoogleFonts.poppins(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Pink Wavy Decoration
class PinkWaveDecoration extends StatelessWidget {
  const PinkWaveDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, 40),
      painter: WavePainter(),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryLight.withOpacity(0.4)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bottom Nav Bar
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFFE91E8F);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 10,
      selectedItemColor: _activeColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      items: [
        BottomNavigationBarItem(
          icon: _BottomNavAssetIcon(
            assetPath: 'assets/icons/home_grey.png',
            isSelected: currentIndex == 0,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _BottomNavAssetIcon(
            assetPath: 'assets/icons/konsul_grey.png',
            isSelected: currentIndex == 1,
          ),
          label: 'Konsultasi',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: _BottomNavAssetIcon(
            assetPath: 'assets/icons/selfheal_grey.png',
            isSelected: currentIndex == 3,
          ),
          label: 'Healing',
        ),
        BottomNavigationBarItem(
          icon: _BottomNavAssetIcon(
            assetPath: 'assets/icons/fyp_grey.png',
            isSelected: currentIndex == 4,
          ),
          label: 'FYP',
        ),
      ],
    );
  }
}

class _BottomNavAssetIcon extends StatelessWidget {
  final String assetPath;
  final bool isSelected;

  const _BottomNavAssetIcon({
    required this.assetPath,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFFE91E8F) : Colors.grey,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        assetPath,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(width: 22, height: 22);
        },
      ),
    );
  }
}