import 'package:flutter/material.dart';
import 'dart:ui';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Función para navegar al login
  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isMobile = screenSize.width <= 800;
    final isTablet = screenSize.width > 800 && screenSize.width <= 1200;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Stack(
        children: [
          // Iluminación de fondo animada
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.5),
                    radius: _pulseAnimation.value * 1.5,
                    colors: [
                      theme.primaryColor.withOpacity(0.15),
                      theme.primaryColor.withOpacity(0.08),
                      theme.primaryColor.withOpacity(0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),

          // Contenido con scroll
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                toolbarHeight: 100,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 40,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo más grande sin sombra
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/img/PCLogoBlanco.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Navegación (solo desktop)
                              if (!isMobile)
                                Row(
                                  children: [
                                    _buildNavButton("Inicio"),
                                    const SizedBox(width: 24),
                                    _buildNavButton("Características"),
                                    const SizedBox(width: 24),
                                    _buildNavButton("Cómo Funciona"),
                                    const SizedBox(width: 24),
                                    _buildNavButton("Precios"),
                                  ],
                                ),

                              // Botón de menú móvil
                              if (isMobile)
                                IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {},
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Sección Hero
              SliverToBoxAdapter(
                child: Container(
                  height: screenSize.height - 80,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  child: isMobile
                      ? _buildMobileHero(theme, screenSize)
                      : _buildDesktopHero(theme, screenSize, isTablet),
                ),
              ),

              // Sección Problema
              SliverToBoxAdapter(
                child: _buildProblemSection(theme, isMobile, isTablet),
              ),

              // Sección Características
              SliverToBoxAdapter(
                child: _buildFeaturesSection(theme, isMobile, isTablet),
              ),

              // Sección Cómo Funciona
              SliverToBoxAdapter(
                child: _buildHowItWorksSection(theme, isMobile, isTablet),
              ),

              // Sección Casos de Uso
              SliverToBoxAdapter(
                child: _buildUseCasesSection(theme, isMobile, isTablet),
              ),

              // Sección Testimonios
              SliverToBoxAdapter(
                child: _buildTestimonialsSection(theme, isMobile, isTablet),
              ),

              // Sección CTA
              SliverToBoxAdapter(
                child: _buildCTASection(theme, isMobile, isTablet),
              ),

              // Footer
              SliverToBoxAdapter(
                child: _buildFooter(theme, isMobile, isTablet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHero(ThemeData theme, Size screenSize, bool isTablet) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CONSTRUYE TU PC IDEAL",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: isTablet ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "La plataforma inteligente que simplifica el armado de PCs",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 42 : 56,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Compatibilidad garantizada, precios optimizados y rendimiento asegurado. "
                  "Nuestro sistema automatiza todo el proceso de selección de componentes.",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: isTablet ? 16 : 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 32,
                          vertical: isTablet ? 16 : 20,
                        ),
                      ),
                      onPressed: _navigateToLogin, // 👈 CONECTADO
                      child: Text(
                        "Comenzar Ahora",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 1,
          child: Container(
            height: screenSize.height * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/img/landingPageImage.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHero(ThemeData theme, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: screenSize.width * 0.8,
          height: screenSize.height * 0.35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/img/landingPageImage.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "CONSTRUYE TU PC IDEAL",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              const Text(
                "La plataforma inteligente que simplifica el armado de PCs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                "Compatibilidad garantizada, precios optimizados y rendimiento asegurado.",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _navigateToLogin, // 👈 CONECTADO
                  child: const Text(
                    "Comenzar Ahora",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Ver Demo",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Resto de los métodos para las secciones...
  // (mantengo solo algunos métodos clave para no hacer el código demasiado largo)

  Widget _buildProblemSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      color: const Color(0xFF111111),
      child: Column(
        children: [
          Text(
            "EL PROBLEMA",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "¿Alguna vez has intentado armar una PC\ny te has sentido abrumado?",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // ... resto del contenido
        ],
      ),
    );
  }

  Widget _buildCTASection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            "¿Listo para construir tu PC ideal?",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Únete a miles de usuarios que ya confían en PConstruct",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isMobile ? 16 : 18,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 32 : 40),

          if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _navigateToLogin, // 👈 CONECTADO
                    child: const Text(
                      "Registrarse Gratis",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // ... resto del contenido
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                  ),
                  onPressed: _navigateToLogin, // 👈 CONECTADO
                  child: const Text(
                    "Registrarse Gratis",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Ver Tutorial",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Métodos auxiliares simplificados
  Widget _buildFeaturesSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            "NUESTRA SOLUCIÓN",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          // ... resto simplificado
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      color: const Color(0xFF111111),
      child: Column(
        children: [
          Text(
            "CÓMO FUNCIONA",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          // ... resto simplificado
        ],
      ),
    );
  }

  Widget _buildUseCasesSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: const Center(
        child: Text("Casos de uso...", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTestimonialsSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: const Center(
        child: Text("Testimonios...", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 40 : 60,
      ),
      color: const Color(0xFF0F0F0F),
      child: const Center(
        child: Text(
          "© 2025 PConstruct. Todos los derechos reservados.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}