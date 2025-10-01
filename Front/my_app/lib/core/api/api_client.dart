import 'package:dio/dio.dart';
// Descomenta la siguiente línea cuando instales flutter_secure_storage
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio = Dio();
  // Almacenamiento seguro para el token JWT
  // final _secureStorage = const FlutterSecureStorage();

  // URL base de tu API Gateway
  final String _baseUrl = 'http://localhost:8000';

  ApiClient() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Interceptor para añadir el token JWT a las peticiones
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ignorar rutas de autenticación
          if (options.path != '/auth/login' &&
              options.path != '/auth/register') {
            // Leer el token del almacenamiento seguro
            // String? token = await _secureStorage.read(key: 'access_token');
            String? token; // Simulación hasta que instales secure_storage

            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            print("Token expirado o inválido. Se necesita re-autenticar.");
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Inicia sesión enviando usuario y contraseña.
  /// Devuelve el mapa completo de la respuesta del Gateway.
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // El API Gateway espera username y password en JSON
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final responseData = response.data;

      if (responseData.containsKey('access_token')) {
        // Guardar el token de forma segura
        // await _secureStorage.write(key: 'access_token', value: responseData['access_token']);
        print("Token guardado exitosamente.");
      }

      return responseData;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'Error desconocido al iniciar sesión.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Registra un nuevo usuario.
  /// Devuelve el mapa con los datos del usuario creado.
  Future<Map<String, dynamic>> register({
    required String name, // Cambió de firstName a name
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name, // Cambió de 'first_name' a 'name'
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'Error desconocido al registrar.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Verifica el código de email.
  /// NOTA: Esta funcionalidad debe implementarse en el backend
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'verification_code': code},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'Error al verificar el código.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Reenvía el código de verificación.
  /// NOTA: Esta funcionalidad debe implementarse en el backend
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'Error al reenviar código.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Solicita recuperación de contraseña.
  /// NOTA: Esta funcionalidad debe implementarse en el backend
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'Error al solicitar recuperación.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Obtiene los datos del usuario actualmente autenticado.
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['message'] ??
              errorData['detail'] ??
              'No se pudo obtener el perfil del usuario.';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }
}
