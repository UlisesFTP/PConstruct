import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/layouts/auth_layout.dart';
import 'package:my_app/core/widgets/custom_text_field.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El usuario es requerido';
    }
    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _navigateToRecovery() {
    Navigator.pushNamed(context, '/recovery');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cerrar el teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      final response = await apiClient.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      Provider.of<AuthProvider>(context, listen: false).login(response);

      _showMessage('¡Bienvenido de vuelta!', isError: false);

      // Pequeño delay para que se vea el mensaje
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/feed', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Breakpoints mejorados
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isSmallMobile = screenWidth < 375;

    // Tamaños adaptativos
    final titleFontSize = isSmallMobile ? 22.0 : (isMobile ? 28.0 : 32.0);
    final subtitleFontSize = isSmallMobile ? 11.0 : (isMobile ? 12.0 : 14.0);
    final bodyFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);
    final buttonFontSize = isSmallMobile ? 15.0 : (isMobile ? 16.0 : 17.0);

    final verticalSpacing = isSmallMobile ? 24.0 : (isMobile ? 32.0 : 40.0);
    final fieldSpacing = isMobile ? 16.0 : 20.0;
    final topPadding = isMobile ? 20.0 : 0.0;

    // Ancho máximo del formulario
    final maxFormWidth = isMobile
        ? double.infinity
        : (isTablet ? 400.0 : 450.0);

    return AuthLayout(
      formContent: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxFormWidth,
              minHeight: isMobile ? 0 : screenHeight * 0.7,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 32.0,
                vertical: isMobile ? 16.0 : 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMobile) SizedBox(height: topPadding),

                    // Encabezado
                    Text(
                      "BIENVENIDO DE NUEVO",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: subtitleFontSize,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Iniciar sesión.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: titleFontSize,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Link a registro
                    GestureDetector(
                      onTap: _navigateToRegister,
                      child: Text.rich(
                        TextSpan(
                          text: "¿No tienes cuenta? ",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: bodyFontSize,
                          ),
                          children: [
                            TextSpan(
                              text: "Crear cuenta",
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: bodyFontSize,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),

                    // Campo de usuario
                    IgnorePointer(
                      ignoring: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.6 : 1.0,
                        child: CustomTextField(
                          controller: _usernameController,
                          hintText: "Usuario",
                          icon: Icons.person_outline,
                          validator: _validateUsername,
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    // Campo de contraseña
                    IgnorePointer(
                      ignoring: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.6 : 1.0,
                        child: CustomTextField(
                          controller: _passwordController,
                          hintText: "Contraseña",
                          icon: Icons.lock_outline,
                          obscureText: _obscureText,
                          validator: _validatePassword,
                          onToggleVisibility: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link a recuperación
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _navigateToRecovery,
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: _isLoading
                                ? theme.primaryColor.withOpacity(0.5)
                                : theme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: bodyFontSize,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),

                    // Botón de login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC7384D),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 16 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _isLoading ? 0 : 2,
                          disabledBackgroundColor: const Color(
                            0xFFC7384D,
                          ).withOpacity(0.6),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              )
                            : Text(
                                "Iniciar sesión",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: buttonFontSize,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    // Espaciado inferior adicional en móvil
                    if (isMobile) SizedBox(height: verticalSpacing),
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
