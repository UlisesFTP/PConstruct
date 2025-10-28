import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/layouts/main_layout.dart';
import 'package:my_app/features/auth/pages/login_page.dart';
import 'package:my_app/features/auth/pages/recovery_page.dart';
import 'package:my_app/features/auth/pages/register_page.dart';
import 'package:my_app/features/auth/pages/verification_page.dart';
import 'package:my_app/features/components/pages/component_detail.dart';
import 'package:my_app/features/feed/pages/feed_page.dart';
import 'package:my_app/features/feed/pages/my_posts_page.dart';
import 'package:my_app/features/profile/pages/profile_page.dart';
import 'package:my_app/features/builds/pages/my_builds_page.dart';
import 'package:my_app/features/settings/pages/settings_page.dart';
import 'package:my_app/features/components/pages/components_page.dart';
import 'package:my_app/features/builds/pages/builds_page.dart';
import 'package:my_app/features/builds/pages/build_constructor_page.dart';
import 'package:my_app/features/benchmarks/pages/benchmarks_page.dart';
import 'package:my_app/landing/pages/landing_page.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/component.dart';

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
        '/feed': (context) => const MainLayout(child: FeedPage()),
        '/profile': (context) => const MainLayout(child: ProfilePage()),
        '/my-posts': (context) => const MainLayout(child: MyPostsPage()),
        '/my-builds': (context) => const MainLayout(child: MyBuildsPage()),
        '/settings': (context) => const MainLayout(child: SettingsPage()),
        '/builds': (context) => MainLayout(child: BuildsPage()),
        '/builds/create': (context) =>
            MainLayout(child: BuildConstructorPage()),
        '/benchmarks': (context) => const MainLayout(child: BenchmarksPage()),
        '/components': (context) => MainLayout(child: ComponentsPage()),
        '/component-detail': (context) {
          final component =
              ModalRoute.of(context)?.settings.arguments as Component?;

          if (component == null) {
            return MainLayout(
              child: Center(
                child: Text(
                  'Error: Componente no encontrado o no proporcionado',
                ),
              ),
            );
          }

          return MainLayout(child: ComponentDetailPage(component: component));
        },
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('Página no encontrada'))),
        );
      },
    );
  }
}
