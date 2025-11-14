import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:provider/provider.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FocusNode _codeFocusNode = FocusNode();
  final TextEditingController _codeController = TextEditingController();
  late ApiClient _apiClient;

  bool _isLoading = false;
  bool _isResending = false;
  String? _userEmail;
  bool _fromRegistration = false;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _codeFocusNode.addListener(() => setState(() {}));

    // Obtener email de los argumentos si viene del registro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _userEmail = args['email'];
          _fromRegistration = args['fromRegistration'] ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _codeFocusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Color getIconColor(FocusNode focusNode) {
    return focusNode.hasFocus ? const Color(0xFFC7384D) : Colors.grey.shade500;
  }

  bool shouldShowGlow(FocusNode focusNode) {
    return focusNode.hasFocus;
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

  // Función para verificar el código
  Future<void> _handleVerification() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Por favor ingresa el código de verificación');
      return;
    }

    if (code.length != 6) {
      _showMessage('El código debe tener 6 dígitos');
      return;
    }

    if (_userEmail == null) {
      _showMessage('Error: Email no encontrado');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.verifyEmail(_userEmail!, code);

      _showMessage('¡Verificación exitosa!', isError: false);

      // Mostrar diálogo de éxito
      _showSuccessDialog();
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('invalid') ||
          errorMessage.contains('inválido')) {
        errorMessage = 'Código de verificación inválido';
      } else if (errorMessage.contains('expired') ||
          errorMessage.contains('expirado')) {
        errorMessage = 'El código ha expirado. Solicita uno nuevo';
      }

      _showMessage('Error: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para reenviar código
  Future<void> _handleResendCode() async {
    if (_userEmail == null) {
      _showMessage('Error: Email no encontrado');
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _apiClient.resendVerificationCode(_userEmail!);
      _showMessage('Código reenviado exitosamente', isError: false);
    } catch (e) {
      _showMessage('Error al reenviar código: ${e.toString()}');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  // Función para cancelar y volver
  void _handleCancel() {
    if (_fromRegistration) {
      // Si viene del registro, volver al registro
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      // Si no, volver al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Función para navegar al login después de verificación exitosa
  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
              Icon(Icons.verified_user, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Verificación Exitosa',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Tu cuenta ha sido verificada exitosamente!',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 12),
              Text(
                'Ya puedes iniciar sesión con tus credenciales.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                  SizedBox(height: isMobile ? 16 : 20),
                  // Título
                  Text(
                    "VERIFICAR CORREO",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isMobile ? 12 : 14,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    "Ingresa el código de verificación",
                    style: theme.textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isMobile ? 20 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 6 : 10),
                  // Descripción con email
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 0 : 32,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Hemos enviado un código de 6 dígitos a:",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isMobile ? 14 : 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_userEmail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _userEmail!,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
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
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        counterText: "", // Oculta el contador de caracteres
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
                  SizedBox(height: isMobile ? 16 : 20),
                  // Reenviar código
                  GestureDetector(
                    onTap: _isResending ? null : _handleResendCode,
                    child: Text.rich(
                      TextSpan(
                        text: "¿No recibiste el código? ",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isMobile ? 14 : 15,
                        ),
                        children: [
                          TextSpan(
                            text: _isResending ? "Enviando..." : "Reenviar",
                            style: TextStyle(
                              color: _isResending
                                  ? Colors.grey.shade600
                                  : theme.primaryColor,
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
                              vertical: isMobile ? 12 : 16,
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleVerification,
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
