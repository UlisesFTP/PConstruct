// lib/core/widgets/layouts/top_nav_links.dart

import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart'; // Importar AppTheme para colores

class TopNavLinks extends StatelessWidget {
  const TopNavLinks({super.key});

  // Determina la ruta activa (esto podría venir de un Provider en el futuro)
  String _getActiveRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name ?? '/feed';
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _getActiveRoute(context);

    return Row(
      children: [
        NavLink(
          text: "Feed",
          isActive: activeRoute == '/feed',
          onTap: () => Navigator.pushNamed(context, '/feed'),
        ),
        const SizedBox(width: 32),
        NavLink(
          text: "Componentes",
          isActive: activeRoute == '/components',
          onTap: () => Navigator.pushNamed(context, '/components'),
        ),
        const SizedBox(width: 32),
        NavLink(
          text: "Builds",
          isActive: activeRoute == '/builds',
          onTap: () => Navigator.pushNamed(context, '/builds'),
        ),
        const SizedBox(width: 32),
        NavLink(
          text: "Benchmarks",
          isActive: activeRoute == '/benchmarks',
          onTap: () => Navigator.pushNamed(context, '/benchmarks'),
        ),
      ],
    );
  }
}

// NavLink ahora acepta onTap
class NavLink extends StatefulWidget {
  final String text;
  final bool isActive;
  final VoidCallback? onTap; // Añadimos onTap

  const NavLink({
    super.key,
    required this.text,
    this.isActive = false,
    this.onTap, // Añadimos al constructor
  });

  @override
  State<NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<NavLink> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isActive || isHovered
        ? theme
              .primaryColor // Usamos color primario del tema
        : theme.colorScheme.secondary; // Usamos color secundario del tema

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click, // Cursor de click
      child: GestureDetector(
        // Usamos GestureDetector para onTap
        onTap: widget.onTap,
        child: Column(
          // Mantenemos Column para la línea inferior
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style:
                  theme.textTheme.bodyLarge?.copyWith(
                    // Usamos estilo de tema bodyLarge
                    color: color,
                    fontWeight: widget.isActive
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ) ??
                  TextStyle(
                    // Fallback
                    color: color,
                    fontWeight: widget.isActive
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 8),
            // Línea inferior animada
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: widget.isActive || isHovered ? 20 : 0, // Ancho animado
              color: theme.primaryColor, // Siempre color primario
            ),
          ],
        ),
      ),
    );
  }
}
