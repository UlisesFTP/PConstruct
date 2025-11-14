import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/layouts/auth_layout.dart';
import 'package:my_app/core/widgets/custom_text_field.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/widgets/profile_picture_modal.dart';
import 'package:provider/provider.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  String? _avatarUrl;

  // Controladores para los campos
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showProfilePictureModal() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    final String? result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePictureModal(apiClient: apiClient),
    );

    if (result != null) {
      setState(() {
        _avatarUrl = result;
      });
    }
  }

  // --- VALIDACIONES (SIN CAMBIOS) ---
  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un nombre de usuario.';
    }
    if (value.length < 4) {
      return 'Debe tener al menos 4 caracteres.';
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
      return 'Por favor ingresa una contraseña.';
    }
    if (value.length < 6) {
      return 'Debe tener al menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña.';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // --- _handleRegister (MODIFICADO) ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate())
      return; // No hacer nada si no es válido

    setState(() {
      _isLoading = true;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final bool registrationSuccess = await apiClient.register(
        _firstNameController.text,
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        avatarUrl: _avatarUrl, // Pasa la URL (opcional)
      );

      if (registrationSuccess && mounted) {
        // Llama al diálogo de éxito en lugar de navegar
        _showSuccessDialog();
      } else if (mounted) {
        // Muestra un error si el APIClient devuelve 'false'
        _showMessage('El registro falló. Revisa tus datos.', isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Muestra cualquier otro error
      if (mounted) {
        _showMessage(e.toString(), isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNCIONES RESTAURADAS ---

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

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

  void _showSuccessDialog() {
    // Detenemos el loading cuando se muestra el diálogo
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

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
                  color: Theme.of(
                    context,
                  ).primaryColor, // Usa el color del tema
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
  // --- FIN DE FUNCIONES RESTAURADAS ---

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AuthLayout(
      // Pasamos el formulario como 'formContent'
      formContent: Form(
        key: _formKey,
        // Usamos SingleChildScrollView para evitar el overflow
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Sección de Avatar (Sin cambios) ---
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF2A2A2A),
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFFA0A0A0),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _showProfilePictureModal,
                      child: const Text(
                        'Seleccionar Foto de Perfil (Opcional)',
                      ),
                    ),
                  ],
                ),
              ),

              // --- Fin Sección de Avatar ---
              SizedBox(height: isMobile ? 16 : 24),
              CustomTextField(
                controller: _firstNameController,
                hintText: 'Nombre',
                icon: Icons.person_outline,
                validator: _validateFirstName,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              CustomTextField(
                controller: _usernameController,
                hintText: 'Nombre de usuario',
                icon: Icons.alternate_email,
                validator: _validateUsername,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                icon: Icons.email_outlined,
                validator: _validateEmail,
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // --- Campos de Contraseña (Corregidos) ---
              CustomTextField(
                controller: _passwordController,
                hintText: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscureText,
                validator: _validatePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              SizedBox(height: isMobile ? 16 : 24),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmText,
                validator: _validateConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmText = !_obscureConfirmText;
                  });
                },
              ),

              // --- Fin Campos de Contraseña ---
              SizedBox(height: isMobile ? 24 : 28),

              SizedBox(
                width: 300,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7384D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
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
                          "Crear cuenta",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : null,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isMobile ? 24 : 28),

              // --- HIPERVÍNCULO DE LOGIN (CORREGIDO) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "¿Ya tienes una cuenta? ",
                    style: TextStyle(color: Colors.white),
                  ),
                  GestureDetector(
                    // Llama a la función restaurada
                    onTap: _navigateToLogin,
                    child: const Text(
                      "Inicia sesión",
                      style: TextStyle(
                        // Color rojo de tu botón (como en la imagen ssad.PNG)
                        color: Color(0xFFC7384D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Espacio al final para el scroll
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
