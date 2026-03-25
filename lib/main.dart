import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'utils/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealinQApp());
}

class HealinQApp extends StatelessWidget {
  const HealinQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'HealinQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/onboarding': (ctx) => const OnboardingScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
