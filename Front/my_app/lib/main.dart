import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/auth/pages/login_page.dart';
import 'package:my_app/features/auth/pages/recovery_page.dart';
import 'package:my_app/features/auth/pages/register_page.dart';
import 'package:my_app/features/auth/pages/verification_page.dart';
import 'package:my_app/features/feed/pages/feed_page.dart';
import 'package:my_app/features/profile/pages/profile_page.dart';
import 'package:my_app/landing/pages/landing_page.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (context, authProvider, previousApiClient) =>
              ApiClient(authProvider: authProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistroPage(),
        '/verification': (context) => const EmailVerificationPage(),
        '/recovery': (context) => const PasswordRecoveryPage(),
        '/feed': (context) => FeedPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
