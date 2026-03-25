import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final bool goToLogin;
  const WelcomeScreen({super.key, required this.goToLogin});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (goToLogin) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpScreen()));
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
