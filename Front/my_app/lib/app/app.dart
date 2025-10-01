import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/landing/pages/landing_page.dart';
import 'package:my_app/features/auth/pages/login_page.dart';
import 'package:my_app/features/auth/pages/register_page.dart';
import 'package:my_app/features/auth/pages/verification_page.dart';
import 'package:my_app/features/auth/pages/recovery_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LandingPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistroPage(),
        '/verification': (context) => const EmailVerificationPage(),
        '/recovery': (context) => const PasswordRecoveryPage(),
      },
    );
  }
}
