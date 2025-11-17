import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      await _apiClient.verifyEmail(_userEmail!, code);

      if (!mounted) return;

      _showMessage('¡Verificación exitosa!', isError: false);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_userEmail == null) {
      _showMessage('Error: Email no encontrado');
      return;
    }

    setState(() => _isResending = true);

    try {
      await _apiClient.resendVerificationCode(_userEmail!);

      if (!mounted) return;

      _showMessage('Código reenviado exitosamente', isError: false);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Error al reenviar código: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _handleCancel() {
    if (_fromRegistration) {
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showSuccessDialog() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.green,
                size: isMobile ? 24 : 28,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'Verificación Exitosa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Tu cuenta ha sido verificada exitosamente!',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                'Ya puedes iniciar sesión con tus credenciales.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
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
                'Ir al Login',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.bold,
                ),
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
    final screenWidth = screenSize.width;

    // Breakpoints mejorados
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isSmallMobile = screenWidth < 375;

    // Configuración responsive mejorada
    final double containerWidth = isMobile
        ? screenWidth * 0.92
        : (isTablet ? screenWidth * 0.75 : 600);

    final double padding = isSmallMobile
        ? 20
        : (isMobile ? 28 : (isTablet ? 36 : 48));
    final double logoSize = isSmallMobile
        ? 70
        : (isMobile ? 80 : (isTablet ? 100 : 120));
    final double iconSize = isSmallMobile ? 56 : (isMobile ? 64 : 80);
    final double iconInnerSize = isSmallMobile ? 28 : (isMobile ? 32 : 40);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 20 : 32,
              ),
              child: Container(
                width: containerWidth,
                constraints: BoxConstraints(
                  minHeight: screenSize.height * (isMobile ? 0.7 : 0.6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
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
                      // Logo
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
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: iconInnerSize,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 20),

                      // Título
                      Text(
                        "VERIFICAR CORREO",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 14),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmallMobile ? 6 : 8),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 0,
                        ),
                        child: Text(
                          "Ingresa el código de verificación",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: isSmallMobile ? 20 : (isMobile ? 22 : 28),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Descripción con email
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 32,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Hemos enviado un código de 6 dígitos a:",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: isSmallMobile
                                    ? 13
                                    : (isMobile ? 14 : 16),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_userEmail != null) ...[
                              SizedBox(height: isMobile ? 6 : 8),
                              Text(
                                _userEmail!,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: isSmallMobile
                                      ? 13
                                      : (isMobile ? 14 : 16),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 28 : 36),

                      // Campo de código de verificación
                      IgnorePointer(
                        ignoring: _isLoading,
                        child: Opacity(
                          opacity: _isLoading ? 0.6 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: shouldShowGlow(_codeFocusNode)
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
                            child: TextField(
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: isMobile ? 3 : 4,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: "000000",
                                counterText: "",
                                prefixIcon: Icon(
                                  Icons.security,
                                  color: getIconColor(_codeFocusNode),
                                  size: isMobile ? 20 : 24,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  letterSpacing: isMobile ? 3 : 4,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2A2A2A),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2A2A2A),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC7384D),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 16 : 18,
                                ),
                              ),
                              onChanged: (value) {
                                if (value.length == 6) {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 24),

                      // Reenviar código
                      GestureDetector(
                        onTap: _isResending || _isLoading
                            ? null
                            : _handleResendCode,
                        child: Text.rich(
                          TextSpan(
                            text: "¿No recibiste el código? ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: isSmallMobile
                                  ? 13
                                  : (isMobile ? 14 : 15),
                            ),
                            children: [
                              TextSpan(
                                text: _isResending ? "Enviando..." : "Reenviar",
                                style: TextStyle(
                                  color: _isResending || _isLoading
                                      ? Colors.grey.shade600
                                      : theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: !_isResending && !_isLoading
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isMobile ? 28 : 36),

                      // Botones
                      isMobile
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallMobile ? 14 : 16,
                                      ),
                                      elevation: _isLoading ? 0 : 2,
                                      disabledBackgroundColor: theme
                                          .primaryColor
                                          .withOpacity(0.6),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _handleVerification,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white.withOpacity(
                                                      0.9,
                                                    ),
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            "Verificar",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallMobile ? 15 : 16,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallMobile ? 14 : 16,
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _handleCancel,
                                    child: Text(
                                      "Cancelar",
                                      style: TextStyle(
                                        color: _isLoading
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallMobile ? 15 : 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey.shade700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _handleCancel,
                                    child: Text(
                                      "Cancelar",
                                      style: TextStyle(
                                        color: _isLoading
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      elevation: _isLoading ? 0 : 2,
                                      disabledBackgroundColor: theme
                                          .primaryColor
                                          .withOpacity(0.6),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _handleVerification,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white.withOpacity(
                                                      0.9,
                                                    ),
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            "Verificar",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
