import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding; // Hacer el padding configurable
  final BorderRadiusGeometry? borderRadius; // Opcional: Borde personalizado

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0), // Padding por defecto
    this.borderRadius, // Por defecto usa el del ClipRRect
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(16.0); // Borde por defecto

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ), // Ajusta el blur si es necesario
        child: Container(
          decoration: BoxDecoration(
            // Usa color de superficie del tema con opacidad
            color: theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ), // Borde sutil
          ),
          padding: padding, // Usa el padding configurable
          child: child,
        ),
      ),
    );
  }
}
