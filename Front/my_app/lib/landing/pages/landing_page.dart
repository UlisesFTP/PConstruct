import 'package:flutter/material.dart';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PConstruct Landing Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFC7384D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC7384D),
          secondary: Colors.grey.shade300,
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: "ProductSans"),
      ),
      // Define tus rutas aquí para que la navegación funcione
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        // '/login': (context) => const LoginPage(), // Asegúrate de tener tu página de login aquí
      },
    );
  }
}

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
              // Header con desenfoque
              SliverAppBar(
                backgroundColor: Colors.black.withOpacity(0.4),
                elevation: 0,
                floating: true,
                snap: true,
                toolbarHeight: 100,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 40,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
              // Sección Hero
              SliverToBoxAdapter(
                child: Container(
                  height: screenSize.height - 100,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  child: isMobile
                      ? _buildMobileHero(theme, screenSize)
                      : _buildDesktopHero(theme, screenSize, isTablet),
                ),
              ),
              // Todas las demás secciones
              SliverToBoxAdapter(
                child: _buildProblemSection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildFeaturesSection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildHowItWorksSection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildUseCasesSection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildTestimonialsSection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildCTASection(theme, isMobile, isTablet),
              ),
              SliverToBoxAdapter(
                child: _buildFooter(theme, isMobile, isTablet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE CONSTRUCCIÓN ---

  Widget _buildNavButton(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDesktopHero(ThemeData theme, Size screenSize, bool isTablet) {
    return Row(
      children: [
        Expanded(
          flex: 1,
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
                "Compatibilidad garantizada, precios optimizados y rendimiento asegurado. Nuestro sistema automatiza todo el proceso de selección de componentes.",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isTablet ? 16 : 18,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
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
                onPressed: _navigateToLogin,
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
                  onPressed: _navigateToLogin,
                  child: const Text(
                    "Comenzar Ahora",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          // ... resto del contenido
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
  ) {
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
          // ... resto del contenido
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

  Widget _buildTestimonialsSection(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
  ) {
    // Tomado de la primera versión
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            "TESTIMONIOS",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Lo que dicen nuestros clientes",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 40 : 60),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            childAspectRatio: isMobile ? 1.2 : 1.1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildTestimonialCard(
                "Excelente trabajo y atención al detalle. Superaron nuestras expectativas.",
                "María García",
                "CEO, TechStart",
              ),
              _buildTestimonialCard(
                "Profesionales comprometidos con resultados de calidad.",
                "Carlos Rodríguez",
                "Director, InnovaCorp",
              ),
              _buildTestimonialCard(
                "La mejor inversión que hemos hecho para nuestro negocio digital.",
                "Ana López",
                "Fundadora, DigitalPlus",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(
    String testimonial,
    String name,
    String position,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, size: 32, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              testimonial,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            position,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
            onPressed: _navigateToLogin,
            child: const Text(
              "Registrarse Gratis",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile, bool isTablet) {
    // Tomado de la primera versión
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 40 : 60,
      ),
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFooterSection("Empresa", [
                  "Sobre nosotros",
                  "Servicios",
                  "Portafolio",
                  "Contacto",
                ]),
                const SizedBox(height: 32),
                _buildFooterSection("Servicios", [
                  "Desarrollo Web",
                  "Apps Móviles",
                  "Cloud Solutions",
                  "Consultoría",
                ]),
                const SizedBox(height: 32),
                _buildFooterSection("Contacto", [
                  "info@empresa.com",
                  "+52 33 1234 5678",
                  "Guadalajara, México",
                ]),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFooterSection("Empresa", [
                    "Sobre nosotros",
                    "Servicios",
                    "Portafolio",
                    "Contacto",
                  ]),
                ),
                Expanded(
                  child: _buildFooterSection("Servicios", [
                    "Desarrollo Web",
                    "Apps Móviles",
                    "Cloud Solutions",
                    "Consultoría",
                  ]),
                ),
                Expanded(
                  child: _buildFooterSection("Contacto", [
                    "info@empresa.com",
                    "+52 33 1234 5678",
                    "Guadalajara, México",
                  ]),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Síguenos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSocialIcon(Icons.facebook),
                          const SizedBox(width: 12),
                          _buildSocialIcon(
                            Icons.link,
                          ), // Placeholder for another icon
                          const SizedBox(width: 12),
                          _buildSocialIcon(Icons.email),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: isMobile ? 32 : 40),
          Container(height: 1, color: Colors.grey.shade800),
          SizedBox(height: isMobile ? 16 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "© 2024 PConstruct. Todos los derechos reservados.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    Text(
                      "Privacidad",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      "Términos",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              item,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.grey.shade400, size: 20),
    );
  }
}
