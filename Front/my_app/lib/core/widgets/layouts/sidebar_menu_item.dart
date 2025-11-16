import 'dart:ui';
import 'package:flutter/material.dart';

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool isDanger; // Para el botón de logout

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.isDanger = false,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.isDanger
        ? Colors.red.shade400
        : theme.primaryColor;
    final inactiveColor = widget.isDanger
        ? Colors.red.shade300.withOpacity(0.7)
        : const Color(0xFFA0A0A0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? activeColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isHovered
                ? Border.all(color: activeColor.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: isHovered ? activeColor : inactiveColor,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: isHovered ? activeColor : inactiveColor,
                          fontSize: 14,
                          fontWeight: isHovered
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Icon(Icons.chevron_right, color: activeColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  String _getActiveRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name ?? '/feed';
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _getActiveRoute(context);
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: const Border(
              top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.dynamic_feed_rounded,
                  label: 'Feed',
                  isActive: activeRoute == '/feed',
                  onTap: () => Navigator.pushNamed(context, '/feed'),
                ),
                _BottomNavItem(
                  icon: Icons.memory,
                  label: 'Componentes',
                  isActive: activeRoute == '/components',
                  onTap: () => Navigator.pushNamed(context, '/components'),
                ),
                _BottomNavItem(
                  icon: Icons.precision_manufacturing,
                  label: 'Builds',
                  isActive: activeRoute == '/builds',
                  onTap: () => Navigator.pushNamed(context, '/builds'),
                ),
                _BottomNavItem(
                  icon: Icons.speed,
                  label: 'Benchmarks',
                  isActive: activeRoute == '/benchmarks',
                  onTap: () => Navigator.pushNamed(context, '/benchmarks'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? theme.primaryColor : const Color(0xFFA0A0A0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
