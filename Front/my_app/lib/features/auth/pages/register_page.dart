import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/auth_layout.dart';
import 'package:my_app/core/widgets/custom_text_field.dart';
import 'package:my_app/core/api/api_client.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;

  // Controladores para los campos
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  @override
  void dispose() {
    _firstNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validaciones
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El usuario es requerido';
    }
    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo letras, números y guiones bajos';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return 'Debe contener al menos una letra y un número';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
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

  // Función para navegar a verificación
  void _navigateToVerification() {
    Navigator.pushNamed(
      context,
      '/verification',
      arguments: {
        'email': _emailController.text.trim(),
        'fromRegistration': true,
      },
    );
  }

  // Función principal de registro
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.register(
        name: _firstNameController.text
            .trim(), // ✅ Correcto: name en vez de firstName
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Registro exitoso
      _showMessage('¡Cuenta creada exitosamente!', isError: false);

      // Mostrar diálogo de éxito y navegar a verificación
      _showSuccessDialog();
    } catch (e) {
      String errorMessage = e.toString();

      // Personalizar mensajes de error comunes
      if (errorMessage.contains('already registered') ||
          errorMessage.contains('ya existe')) {
        errorMessage = 'El usuario o email ya están registrados';
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
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Registro Exitoso',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu cuenta ha sido creada exitosamente.',
                style: TextStyle(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 12),
              Text(
                'Hemos enviado un código de verificación a:',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text.trim(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, verifica tu correo para activar tu cuenta.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Ir a verificación',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToVerification();
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
    final isMobile = MediaQuery.of(context).size.width <= 800;

    // Widget para los campos de Nombre y Usuario
    Widget nameFields() {
      if (isMobile) {
        return Column(
          children: [
            CustomTextField(
              controller: _firstNameController,
              hintText: "Nombre",
              icon: Icons.person_outline,
              validator: _validateFirstName,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _usernameController,
              hintText: "Usuario",
              icon: Icons.person_outline,
              validator: _validateUsername,
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _firstNameController,
              hintText: "Nombre",
              icon: Icons.assignment_ind_outlined,
              validator: _validateFirstName,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomTextField(
              controller: _usernameController,
              hintText: "Usuario",
              icon: Icons.person_outline,
              validator: _validateUsername,
            ),
          ),
        ],
      );
    }

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
              onTap: _navigateToLogin,
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

            nameFields(),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
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
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: "Confirmar Contraseña",
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmText,
              validator: _validateConfirmPassword,
              onToggleVisibility: () =>
                  setState(() => _obscureConfirmText = !_obscureConfirmText),
            ),
            SizedBox(height: isMobile ? 24 : 28),

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
                onPressed: _isLoading ? null : _handleRegister,
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
    );
  }
}
