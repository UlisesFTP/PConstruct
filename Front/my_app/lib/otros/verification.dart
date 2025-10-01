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
      title: 'Verificación de Correo',
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
      home: const EmailVerificationPage(),
    );
  }
}

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FocusNode _codeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeFocusNode.dispose();
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
    double containerWidth = screenSize.width * 0.6;
    double padding = 48;
    double logoSize = 120;

    if (isMobile) {
      containerWidth = screenSize.width * 0.9;
      padding = 24;
      logoSize = 80;
    } else if (isTablet) {
      containerWidth = screenSize.width * 0.7;
      padding = 36;
      logoSize = 100;
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 21, 21),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: containerWidth,
            // Removemos altura fija y usamos constraints mínimas
            constraints: BoxConstraints(minHeight: screenSize.height * 0.6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1C), // Color gris oscuro opaco
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Importante: usar min
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo centrado
                  Container(
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
                  SizedBox(height: isMobile ? 20 : 28), // Reducido
                  // Icono de email
                  Container(
                    width: isMobile ? 60 : 80,
                    height: isMobile ? 60 : 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: isMobile ? 32 : 40,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20), // Reducido
                  // Título
                  Text(
                    "VERIFICAR CORREO",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isMobile ? 12 : 14,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6), // Reducido
                  Text(
                    "Ingresa el código de verificación",
                    style: theme.textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isMobile ? 20 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 6 : 10), // Reducido
                  // Descripción
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 0 : 32,
                    ),
                    child: Text(
                      "Hemos enviado un código de 6 dígitos a tu correo electrónico. Por favor, ingrésalo a continuación para verificar tu cuenta.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isMobile ? 14 : 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32), // Reducido
                  // Campo de código de verificación
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: shouldShowGlow(_codeFocusNode)
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
                      focusNode: _codeFocusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        prefixIcon: Icon(
                          Icons.security,
                          color: getIconColor(_codeFocusNode),
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20), // Reducido
                  // Reenviar código
                  GestureDetector(
                    onTap: () {},
                    child: Text.rich(
                      TextSpan(
                        text: "¿No recibiste el código? ",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isMobile ? 14 : 15,
                        ),
                        children: [
                          TextSpan(
                            text: "Reenviar",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32), // Reducido
                  // Botones
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16, // Reducido
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón Verificar
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16, // Reducido
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "Verificar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                          ),
                        ),
                      ),
                    ],
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
