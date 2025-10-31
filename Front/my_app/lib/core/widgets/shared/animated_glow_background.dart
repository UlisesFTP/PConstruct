import 'package:flutter/material.dart';

class AnimatedGlowBackground extends StatefulWidget {
  const AnimatedGlowBackground({super.key});

  @override
  State<AnimatedGlowBackground> createState() => _AnimatedGlowBackgroundState();
}

class _AnimatedGlowBackgroundState extends State<AnimatedGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Puedes ajustar la duración
    )..repeat(reverse: true);

    // Animación más sutil y lenta para el fondo general
    _animation = Tween<double>(begin: 0.08, end: 0.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Obtiene el tema actual

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          // Cubre toda el área disponible
          decoration: BoxDecoration(
            gradient: RadialGradient(
              // Posición y radio ajustados para un efecto de fondo
              center: const Alignment(-0.6, -0.7),
              radius: 1.8, // Radio más grande
              colors: [
                theme.primaryColor.withOpacity(
                  _animation.value,
                ), // Usa el color primario del tema
                theme.primaryColor.withOpacity(_animation.value * 0.5),
                Colors.transparent, // Transparente hacia los bordes
              ],
              stops: const [0.0, 0.4, 1.0], // Ajusta las paradas
            ),
          ),
        );
      },
    );
  }
}
