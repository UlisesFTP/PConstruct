import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landing Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFC7384D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC7384D),
          secondary: Colors.grey.shade300,
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: "ProductSans"),
      ),
      home: const LandingPage(),
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
                toolbarHeight: 80,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Container(
                          width: isMobile ? 60 : 80,
                          height: isMobile ? 60 : 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
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
                              _buildNavButton("Servicios"),
                              const SizedBox(width: 24),
                              _buildNavButton("Portafolio"),
                              const SizedBox(width: 24),
                              _buildNavButton("Contacto"),
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

              // Sección Servicios
              SliverToBoxAdapter(
                child: _buildServicesSection(theme, isMobile, isTablet),
              ),

              // Sección Portafolio
              SliverToBoxAdapter(
                child: _buildPortfolioSection(theme, isMobile, isTablet),
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

  dNavButton(String text) {
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
                  "BIENVENIDO AL FUTURO",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: isTablet ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "Transformamos tus ideas en realidad digital",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 42 : 56,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "La plataforma inteligente que simplifica el armado de PCs Compatibilidad garantizada, precios optimizados y rendimiento asegurado.",
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
                      onPressed: () {},
                      child: Text(
                        "Comenzar proyecto",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 14 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 32,
                          vertical: isTablet ? 16 : 20,
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        "Ver portafolio",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
                "BIENVENIDO AL FUTURO",
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
                "Transformamos tus ideas en realidad digital",
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
                "Creamos experiencias digitales excepcionales que impulsan tu negocio hacia el éxito.",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            "NUESTROS SERVICIOS",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Soluciones tecnológicas completas",
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
            childAspectRatio: isMobile ? 1.5 : 1.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildServiceCard(
                theme,
                Icons.web,
                "Desarrollo Web",
                "Sitios web modernos y responsivos",
              ),
              _buildServiceCard(
                theme,
                Icons.phone_android,
                "Apps Móviles",
                "Aplicaciones nativas e híbridas",
              ),
              _buildServiceCard(
                theme,
                Icons.cloud,
                "Cloud Solutions",
                "Infraestructura en la nube",
              ),
              _buildServiceCard(
                theme,
                Icons.design_services,
                "UI/UX Design",
                "Diseño de experiencia de usuario",
              ),
              _buildServiceCard(
                theme,
                Icons.analytics,
                "Analytics",
                "Análisis de datos y métricas",
              ),
              _buildServiceCard(
                theme,
                Icons.support_agent,
                "Soporte 24/7",
                "Mantenimiento y soporte técnico",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      color: const Color(0xFF111111),
      child: Column(
        children: [
          Text(
            "NUESTRO TRABAJO",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Proyectos que transforman negocios",
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
            childAspectRatio: 1.3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildPortfolioCard(
                "E-commerce Platform",
                "Plataforma completa de comercio electrónico",
              ),
              _buildPortfolioCard(
                "Banking App",
                "Aplicación móvil para servicios bancarios",
              ),
              _buildPortfolioCard(
                "Healthcare System",
                "Sistema integral de gestión hospitalaria",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(String title, String description) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
  ) {
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
            "¿Listo para comenzar tu proyecto?",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Contactanos hoy y convierte tu visión en realidad",
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
                    onPressed: () {},
                    child: const Text(
                      "Comenzar ahora",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                      "Agendar consulta",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
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
                  onPressed: () {},
                  child: const Text(
                    "Comenzar ahora",
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
                    "Agendar consulta",
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

  Widget _buildFooter(ThemeData theme, bool isMobile, bool isTablet) {
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
                          _buildSocialIcon(Icons.link),
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
                "© 2024 Tu Empresa. Todos los derechos reservados.",
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
}
