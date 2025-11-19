// lib/main.dart
import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/layouts/main_layout.dart';
import 'package:my_app/features/auth/pages/login_page.dart';
import 'package:my_app/features/auth/pages/recovery_page.dart';
import 'package:my_app/features/auth/pages/register_page.dart';
import 'package:my_app/features/auth/pages/verification_page.dart';
import 'package:my_app/features/auth/pages/reset_password_page.dart';
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
import 'package:url_strategy/url_strategy.dart';

Future<void> main() async {
  // Asegura que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Quita el # de las URLs en web
  setPathUrlStrategy();

  runApp(const PConstructApp());
}

class PConstructApp extends StatelessWidget {
  const PConstructApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configura los Providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (context, auth, previousApiClient) =>
              ApiClient(authProvider: auth),
        ),
      ],
      child: const MyApp(), // Llama al widget principal de la app
    );
  }
}

// Este es tu widget principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PConstruct',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,

      // --- MANEJO DE ESTADO DE SESIÓN ---
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 1. Splash Screen mientras carga
          if (auth.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F0F0F),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 197, 0, 72),
                ),
              ),
            );
          }

          // 2. Si no está autenticado, ir a Landing
          if (!auth.isAuthenticated) {
            return const LandingPage();
          }

          // 3. Si está autenticado, ir al Feed
          return const MainLayout(child: FeedPage());
        },
      ),

      // --- RUTAS DINÁMICAS (PARA EL RESET DE CONTRASEÑA) ---
      onGenerateRoute: (settings) {
        // Interceptamos la navegación para buscar parámetros en la URL
        if (settings.name != null) {
          final uri = Uri.parse(settings.name!);

          // Si la ruta es /reset-password
          if (uri.path == '/reset-password') {
            // Extraemos el token de ?token=XYZ
            final token = uri.queryParameters['token'];

            // Si hay token, mostramos la página de reseteo
            if (token != null) {
              return MaterialPageRoute(
                builder: (context) => ResetPasswordPage(token: token),
              );
            }
          }
        }
        // Si no coincide, dejamos que Flutter use 'routes' o muestre 404
        return null;
      },

      // --- RUTAS ESTÁTICAS ---
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistroPage(),
        '/recovery': (context) =>
            const PasswordRecoveryPage(), // Asegúrate de que esta ruta exista en tu flujo
        '/verification': (context) => const EmailVerificationPage(),
        '/feed': (context) => const MainLayout(child: FeedPage()),
        '/profile': (context) => const MainLayout(child: ProfilePage()),
        '/my-posts': (context) => const MainLayout(child: MyPostsPage()),
        '/my-builds': (context) => const MainLayout(child: MyBuildsPage()),
        '/settings': (context) => const MainLayout(child: SettingsPage()),
        '/builds': (context) => const MainLayout(child: BuildsPage()),
        '/builds/create': (context) =>
            MainLayout(child: BuildConstructorPage()),
        '/benchmarks': (context) => const MainLayout(child: BenchmarksPage()),
        '/components': (context) => const MainLayout(child: ComponentsPage()),
        '/component-detail': (context) {
          final componentId =
              ModalRoute.of(context)?.settings.arguments as int?;

          if (componentId == null) {
            return const MainLayout(
              child: Center(
                child: Text('Error: ID de componente no proporcionado'),
              ),
            );
          }
          return MainLayout(
            child: ComponentDetailPage(componentId: componentId),
          );
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
