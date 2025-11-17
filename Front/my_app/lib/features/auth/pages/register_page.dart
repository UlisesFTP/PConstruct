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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Cerrar el teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final bool registrationSuccess = await apiClient.register(
        _firstNameController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;

      if (registrationSuccess) {
        _showSuccessDialog();
      } else {
        _showMessage('El registro falló. Revisa tus datos.', isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString(), isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isMobile = MediaQuery.of(context).size.width < 600;

        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: isMobile ? 24 : 28,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'Registro Exitoso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu cuenta ha sido creada exitosamente.',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                Text(
                  'Hemos enviado un código de verificación a:',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailController.text.trim(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                Text(
                  'Por favor, verifica tu correo para activar tu cuenta.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 10 : 12,
                ),
              ),
              child: Text(
                'Ir a verificación',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.bold,
                ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isSmallMobile = screenWidth < 375;

    // Tamaños adaptativos
    final avatarRadius = isSmallMobile ? 40.0 : (isMobile ? 45.0 : 50.0);
    final fieldSpacing = isSmallMobile ? 14.0 : (isMobile ? 16.0 : 20.0);
    final sectionSpacing = isSmallMobile ? 20.0 : (isMobile ? 24.0 : 28.0);
    final buttonFontSize = isSmallMobile ? 15.0 : (isMobile ? 16.0 : 17.0);
    final bodyFontSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);

    // Ancho máximo del formulario
    final maxFormWidth = isMobile
        ? double.infinity
        : (isTablet ? 450.0 : 500.0);

    return AuthLayout(
      formContent: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxFormWidth,
              minHeight: isMobile ? 0 : screenHeight * 0.8,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 32.0,
                vertical: isMobile ? 20.0 : 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isLoading ? null : _showProfilePictureModal,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  backgroundImage: _avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child: _avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: avatarRadius * 0.9,
                                          color: const Color(0xFFA0A0A0),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC7384D),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1A1A1C),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: isMobile ? 16 : 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : _showProfilePictureModal,
                            child: Text(
                              'Seleccionar Foto de Perfil (Opcional)',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                color: _isLoading
                                    ? Colors.grey.shade600
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    // Form Fields - Con IgnorePointer para deshabilitar
                    IgnorePointer(
                      ignoring: _isLoading,
                      child: Opacity(
                        opacity: _isLoading ? 0.6 : 1.0,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _firstNameController,
                              hintText: 'Nombre',
                              icon: Icons.person_outline,
                              validator: _validateFirstName,
                            ),
                            SizedBox(height: fieldSpacing),
                            CustomTextField(
                              controller: _usernameController,
                              hintText: 'Nombre de usuario',
                              icon: Icons.alternate_email,
                              validator: _validateUsername,
                            ),
                            SizedBox(height: fieldSpacing),
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: fieldSpacing),
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
                            SizedBox(height: fieldSpacing),
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
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    // Register Button
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
                        onPressed: _isLoading ? null : _handleRegister,
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
                                "Crear cuenta",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: buttonFontSize,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _navigateToLogin,
                        child: Text.rich(
                          TextSpan(
                            text: "¿Ya tienes una cuenta? ",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: bodyFontSize,
                            ),
                            children: [
                              TextSpan(
                                text: "Inicia sesión",
                                style: TextStyle(
                                  color: _isLoading
                                      ? const Color(0xFFC7384D).withOpacity(0.5)
                                      : const Color(0xFFC7384D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: bodyFontSize,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isMobile) SizedBox(height: sectionSpacing),
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
