import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Color getIconColor(FocusNode focusNode) {
    return focusNode.hasFocus ? const Color(0xFFC7384D) : Colors.grey.shade500;
  }

  bool shouldShowGlow(FocusNode focusNode) {
    return focusNode.hasFocus;
  }

  // Validación de email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  // Función para mostrar mensajes
  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Función para navegar al login
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Función para cancelar
  void _handleCancel() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Función principal de recuperación
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.requestPasswordReset(_emailController.text.trim());

      _showMessage(
        'Enlace de recuperación enviado exitosamente',
        isError: false,
      );

      // Mostrar diálogo de éxito
      _showSuccessDialog();
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('not found') ||
          errorMessage.contains('no encontrado')) {
        errorMessage = 'Email no encontrado en el sistema';
      } else if (errorMessage.contains('conexión') ||
          errorMessage.contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      }

      _showMessage('Error: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Diálogo de éxito
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1C),
          title: Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Enlace Enviado',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hemos enviado un enlace de recuperación a:',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text.trim(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Si no encuentras el correo, revisa tu carpeta de spam.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Ir al Login',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
            ),
          ],
        );
      },
    );
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
            constraints: BoxConstraints(minHeight: screenSize.height * 0.6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1C),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    SizedBox(height: isMobile ? 20 : 28),
                    // Icono de llave/contraseña
                    Container(
                      width: isMobile ? 60 : 80,
                      height: isMobile ? 60 : 80,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.key_outlined,
                        size: isMobile ? 32 : 40,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    // Título
                    Text(
                      "RECUPERAR CONTRASEÑA",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: isMobile ? 12 : 14,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      "Ingresa tu correo electrónico",
                      style: theme.textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isMobile ? 20 : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 6 : 10),
                    // Descripción
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 0 : 32,
                      ),
                      child: Text(
                        "Te enviaremos un enlace de recuperación para restablecer tu contraseña. Asegúrate de revisar tu bandeja de entrada y spam.",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isMobile ? 14 : 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),
                    // Campo de email
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: shouldShowGlow(_emailFocusNode)
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFC7384D,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        decoration: InputDecoration(
                          hintText: "Correo electrónico",
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: getIconColor(_emailFocusNode),
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFFC7384D),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    // Recordar datos de acceso
                    GestureDetector(
                      onTap: _navigateToLogin,
                      child: Text.rich(
                        TextSpan(
                          text: "¿Recordaste tu contraseña? ",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isMobile ? 14 : 15,
                          ),
                          children: [
                            TextSpan(
                              text: "Iniciar sesión",
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),
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
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleCancel,
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
                        // Botón Enviar
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            onPressed: _isLoading ? null : _handlePasswordReset,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Enviar enlace",
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
      ),
    );
  }
}
