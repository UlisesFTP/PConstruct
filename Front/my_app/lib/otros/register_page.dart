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
      title: 'Registro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFC7384D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC7384D),
          secondary: Colors.grey.shade300,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC7384D), width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: "ProductSans"),
      ),
      home: const RegistroPage(),
    );
  }
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _firstNameFocusNode.addListener(() => setState(() {}));
    _lastNameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Color getIconColor(FocusNode focusNode) {
    return focusNode.hasFocus ? const Color(0xFFC7384D) : Colors.grey.shade500;
  }

  bool shouldShowGlow(FocusNode focusNode) {
    return focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 800 && screenSize.width <= 1200;
    final isMobile = screenSize.width <= 800;

    // Configuración responsive
    double containerWidth = screenSize.width * 0.95;
    double containerHeight = screenSize.height * 0.9;
    double formWidth = screenSize.width * 0.45;
    double padding = 48;
    double logoSize = 180;
    double logoTop = -32;
    double logoLeft = 25;

    if (isMobile) {
      containerWidth = screenSize.width * 0.95;
      containerHeight = screenSize.height * 0.95;
      formWidth = screenSize.width * 0.9;
      padding = 20;
      logoSize = 100;
      logoTop = 20;
      logoLeft = screenSize.width * 0.7;
    } else if (isTablet) {
      containerWidth = screenSize.width * 0.9;
      containerHeight = screenSize.height * 0.85;
      formWidth = screenSize.width * 0.5;
      padding = 32;
      logoSize = 140;
      logoTop = -20;
      logoLeft = 30;
    }

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
                  // Degradado responsive
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: isMobile
                              ? const Alignment(0, -1) // Vertical en móvil
                              : const Alignment(
                                  -0.5,
                                  -0.120,
                                ), // Diagonal en desktop
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
                          stops: isMobile
                              ? const [0.0, 0.4, 0.6, 0.8, 1.0]
                              : const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Logotipo responsive
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
                  // Contenido del formulario responsive
                  Positioned(
                    left: 0,
                    top: isMobile ? logoSize + 40 : 0,
                    bottom: 0,
                    width: formWidth,
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: isMobile
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) const SizedBox(height: 20),
                          Text(
                            "ÚNETE A LA COMUNIDAD",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: isMobile ? 12 : 14,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            "Crear nueva cuenta.",
                            style: theme.textTheme.headlineMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: isMobile ? 24 : null,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          GestureDetector(
                            onTap: () {},
                            child: Text.rich(
                              TextSpan(
                                text: "¿Ya tienes cuenta? ",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: isMobile ? 14 : null,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Iniciar sesión",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 32),
                          // Nombres - Stack responsive
                          if (isMobile)
                            // Nombres en vertical para móvil
                            Column(
                              children: [
                                _buildTextField(
                                  focusNode: _firstNameFocusNode,
                                  hintText: "Nombre",
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  focusNode: _lastNameFocusNode,
                                  hintText: "Usuario",
                                  icon: Icons.person_outline,
                                ),
                              ],
                            )
                          else
                            // Nombres en horizontal para desktop/tablet
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    focusNode: _firstNameFocusNode,
                                    hintText: "Nombre",
                                    icon: Icons.assignment_ind_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    focusNode: _lastNameFocusNode,
                                    hintText: "Usuario",
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Email
                          _buildTextField(
                            focusNode: _emailFocusNode,
                            hintText: "Email",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          // Password
                          _buildTextField(
                            focusNode: _passwordFocusNode,
                            hintText: "Contraseña",
                            icon: Icons.lock_outline,
                            obscureText: _obscureText,
                            onToggleVisibility: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                          const SizedBox(height: 16),
                          // Confirmar Password
                          _buildTextField(
                            focusNode: _confirmPasswordFocusNode,
                            hintText: "Confirmar Contraseña",
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmText,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmText = !_obscureConfirmText,
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 28),
                          // Botón responsive
                          SizedBox(
                            width: isMobile ? double.infinity : 250,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 16 : 20,
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                "Crear cuenta",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: shouldShowGlow(focusNode)
            ? [
                BoxShadow(
                  color: const Color(0xFFC7384D).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextField(
        focusNode: focusNode,
        obscureText: obscureText ?? false,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: getIconColor(focusNode)),
          suffixIcon: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    (obscureText ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: getIconColor(focusNode),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}
