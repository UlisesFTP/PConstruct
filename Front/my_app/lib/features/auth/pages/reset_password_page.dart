import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
// Asegúrate de importar tu ApiClient

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Asegúrate de tener una instancia de tu ApiClient en tu _ResetPasswordPageState
  final ApiClient _apiClient = ApiClient();
  // Instancia de tu ApiClient
  // final ApiClient _apiClient = ApiClient();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = true}) {
    // ... (tu función para mostrar SnackBars)
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // --- FUNCIÓN ACTIVADA ---
      await _apiClient.resetPassword(widget.token, _passwordController.text);

      _showMessage('¡Contraseña actualizada con éxito!', isError: false);

      // Redirigir al login después de un momento
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Buena práctica: verificar que el widget sigue en el árbol
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      });
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aquí construirías la UI, similar a tu página de login/registro,
    // pero con dos campos de contraseña y un botón de "Restablecer".
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer Contraseña')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                ),
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Restablecer Contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
