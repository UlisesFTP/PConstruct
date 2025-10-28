import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/layouts/sidebar_menu_item.dart';
import 'package:provider/provider.dart'; // <-- Importar Provider
import 'package:my_app/providers/auth_provider.dart'; // <-- Importar AuthProvider

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
  const SidebarContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2.5),
                child: Row(
                  children: [
                    Image.asset('assets/img/PCLogoBlanco.png', height: 180),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SidebarMenuItem(
                      icon: Icons.person_outline,
                      text: 'Usuario',
                      onTap: () {
                        Navigator.pop(context); // Cierra el drawer
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.build_outlined,
                      text: 'Mis builds',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-builds');
                        // Navigator.pushNamed(context, '/my-builds');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.article_outlined,
                      text: 'Mis publicaciones',
                      onTap: () {
                        // <-- ¡NUEVA NAVEGACIÓN!
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/my-posts');
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.settings_outlined,
                      text: 'Configuración',
                      onTap: () {
                        // <-- ¡ACTUALIZADO!
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
              ),
              SidebarMenuItem(
                icon: Icons.logout,
                text: 'Cerrar sesión',
                onTap: () {
                  // <-- ¡NUEVA LÓGICA DE LOGOUT!
                  // 1. Llama al método logout del provider
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  // 2. Navega al login y elimina todas las rutas anteriores
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
