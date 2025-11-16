import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/layouts/sidebar_menu_item.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withOpacity(0.6),
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: const SidebarContent(),
        ),
      ),
    );
  }
}

class SidebarContent extends StatelessWidget {
  const SidebarContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.username ?? 'Usuario';
    final userEmail = authProvider.user?.email ?? '';

    return Stack(
      children: [
        // Gradiente de fondo
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [
                  const Color(0xFFC7384D).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Contenido
        Column(
          children: [
            // Header con logo y info de usuario
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Logo
                  Image.asset('assets/img/PCLogoBlanco.png', height: 80),
                  const SizedBox(height: 20),

                  // Info de usuario
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFC7384D),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (userEmail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: Color(0xFFA0A0A0),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 12),

            // Menú principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    SidebarMenuItem(
                      icon: Icons.person_outline,
                      text: 'Perfil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.precision_manufacturing,
                      text: 'Mis Builds',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-builds');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.article_outlined,
                      text: 'Mis Publicaciones',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-posts');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.bookmark_outline,
                      text: 'Guardados',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, '/saved');
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFF2A2A2A), height: 1),
                    ),

                    SidebarMenuItem(
                      icon: Icons.settings_outlined,
                      text: 'Configuración',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.help_outline,
                      text: 'Ayuda',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, '/help');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Botón de logout
            Padding(
              padding: const EdgeInsets.all(8),
              child: SidebarMenuItem(
                icon: Icons.logout,
                text: 'Cerrar Sesión',
                isDanger: true, // Marca como peligroso
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}
