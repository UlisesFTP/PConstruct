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

class TopNavIcons extends StatelessWidget {
  final bool showLabels;

  const TopNavIcons({super.key, this.showLabels = true});

  String _getActiveRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name ?? '/feed';
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _getActiveRoute(context);

    final navItems = [
      NavItemData(
        icon: Icons.dynamic_feed_rounded,
        label: 'Feed',
        route: '/feed',
      ),
      NavItemData(
        icon: Icons.memory,
        label: 'Componentes',
        route: '/components',
      ),
      NavItemData(
        icon: Icons.precision_manufacturing,
        label: 'Builds',
        route: '/builds',
      ),
      NavItemData(icon: Icons.speed, label: 'Benchmarks', route: '/benchmarks'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: navItems.map((item) {
        final isActive = activeRoute == item.route;
        return NavIconButton(
          icon: item.icon,
          label: item.label,
          isActive: isActive,
          showLabel: showLabels,
          onTap: () => Navigator.pushNamed(context, item.route),
        );
      }).toList(),
    );
  }
}

class NavItemData {
  final IconData icon;
  final String label;
  final String route;

  NavItemData({required this.icon, required this.label, required this.route});
}

class NavIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showLabel;
  final VoidCallback onTap;

  const NavIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.showLabel,
    required this.onTap,
  });

  @override
  State<NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<NavIconButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isActive || isHovered
        ? theme.primaryColor
        : const Color(0xFFA0A0A0);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.showLabel ? 12 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? theme.primaryColor.withOpacity(0.15)
                : (isHovered
                      ? theme.primaryColor.withOpacity(0.08)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: widget.isActive
                ? Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: widget.showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 22, color: color),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: widget.isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 24, color: color),
                    if (widget.isActive) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
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
