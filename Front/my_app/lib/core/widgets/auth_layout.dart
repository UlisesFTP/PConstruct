import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget formContent;

  const AuthLayout({super.key, required this.formContent});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width <= 800;

    // Lógica responsive para el layout
    double containerWidth = isMobile
        ? screenSize.width * 0.95
        : screenSize.width * 0.95;
    double containerHeight = isMobile
        ? screenSize.height * 0.95
        : screenSize.height * 0.9;
    double formWidth = isMobile
        ? screenSize.width * 0.9
        : screenSize.width * 0.45;
    double logoSize = isMobile ? 100 : 180;
    double logoTop = isMobile ? 20 : -32;
    double logoLeft = isMobile
        ? (screenSize.width * 0.95 - logoSize) / 2
        : 25; // Centrado en móvil

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 21, 21),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Imagen de fondo
                  Positioned.fill(
                    child: Image.asset(
                      'assets/img/example_background1.PNG',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Degradado
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: isMobile
                              ? const Alignment(0, -1)
                              : const Alignment(-0.5, -0.120),
                          end: isMobile
                              ? const Alignment(0, 1)
                              : const Alignment(0.5, 0.120),
                          colors: [
                            const Color(0xFF1A1A1C).withOpacity(1),
                            const Color(0xFF1A1A1C).withOpacity(0.95),
                            const Color(
                              0xFF1A1A1C,
                            ).withOpacity(isMobile ? 0.9 : 0.8),
                            const Color(
                              0xFF1A1A1C,
                            ).withOpacity(isMobile ? 0.7 : 0.45),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Logo
                  Positioned(
                    top: logoTop,
                    left: logoLeft,
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/img/PCLogoBlanco.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Contenido del Formulario (pasado como parámetro)
                  Positioned(
                    left: 0,
                    top: isMobile ? logoSize + 20 : 0,
                    bottom: 0,
                    width: formWidth,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20 : 48),
                      child: formContent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
