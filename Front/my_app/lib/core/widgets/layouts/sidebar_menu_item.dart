import 'package:flutter/material.dart';

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = Colors.grey[400];

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Material(
        color: isHovered ? activeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,

          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isHovered ? activeColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: isHovered ? activeColor : inactiveColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: isHovered ? activeColor : inactiveColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
