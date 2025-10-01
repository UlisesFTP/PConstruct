import 'package:flutter/material.dart';
import 'package:my_app/features/auth/widgets/auth_layout.dart';
import 'package:my_app/core/widgets/custom_text_field.dart';
import 'package:my_app/core/api/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;

  // Controladores para los campos
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para validar usuario
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El usuario es requerido';
    }
    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }

  // Función para validar contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Función para mostrar mensajes de error/éxito
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

  // Función para navegar al registro
  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  // Función para navegar a recuperación de contraseña
  void _navigateToRecovery() {
    Navigator.pushNamed(context, '/recovery');
  }

  // Función principal de login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Login exitoso
      _showMessage('¡Inicio de sesión exitoso!', isError: false);

      // Aquí puedes navegar a la página principal de la app
      // Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);

      // Por ahora, solo mostrar un diálogo de éxito
      _showSuccessDialog(response);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Diálogo de éxito con información del usuario
  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1C),
          title: const Text(
            'Login Exitoso',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido de vuelta!',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 8),
              if (response['user'] != null) ...[
                Text(
                  'Usuario: ${response['user']['username'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                Text(
                  'Email: ${response['user']['email'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                Text(
                  'Rol: ${response['user']['role'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Continuar',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width <= 800;

    return AuthLayout(
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) const SizedBox(height: 20),
            Text(
              "BIENVENIDO DE NUEVO",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isMobile ? 12 : 14,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              "Iniciar sesión.",
              style: theme.textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isMobile ? 24 : null,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            GestureDetector(
              onTap: _navigateToRegister,
              child: Text.rich(
                TextSpan(
                  text: "¿No tienes cuenta? ",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isMobile ? 14 : null,
                  ),
                  children: [
                    TextSpan(
                      text: "Crear cuenta",
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
            SizedBox(height: isMobile ? 32 : 40),

            CustomTextField(
              controller: _usernameController,
              hintText: "Usuario",
              icon: Icons.person_outline,
              validator: _validateUsername,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: "Contraseña",
              icon: Icons.lock_outline,
              obscureText: _obscureText,
              validator: _validatePassword,
              onToggleVisibility: () =>
                  setState(() => _obscureText = !_obscureText),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _navigateToRecovery,
                child: Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 32 : 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFC7384D,
                  ), // Color rojo específico
                  foregroundColor: Colors.white, // Texto blanco
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white, // Loading indicator blanco
                          ),
                        ),
                      )
                    : Text(
                        "Iniciar sesión",
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
    );
  }
}
