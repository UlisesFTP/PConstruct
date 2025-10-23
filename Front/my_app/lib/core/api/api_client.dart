import 'package:dio/dio.dart';
// Importamos ambos archivos de modelos
import '../../models/posts.dart';
import '../../models/search_results.dart';
import '../../models/comment.dart';
import 'package:my_app/providers/auth_provider.dart'; // <-- IMPORTANTE

// Descomenta la siguiente línea cuando instales flutter_secure_storage
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8000';
  final AuthProvider? authProvider; // <-- AÑADE ESTO

  ApiClient({this.authProvider}) {
    // <-- MODIFICA EL CONSTRUCTOR
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path != '/auth/login' &&
              options.path != '/auth/register') {
            // --- CORRECCIÓN AQUÍ: Leemos el token desde el AuthProvider ---
            final token = authProvider?.token;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final responseData = response.data;
      if (responseData.containsKey('access_token')) {
        // await _secureStorage.write(key: 'access_token', value: responseData['access_token']);
        print("Token guardado exitosamente.");
      }
      return responseData;
    } on DioException catch (e) {
      _handleDioError(e, 'Error desconocido al iniciar sesión.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error desconocido al registrar.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'verification_code': code},
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al verificar el código.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al reenviar código.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        '/auth/request-password-reset',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al solicitar recuperación.');
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
      if (response.statusCode != 200) {
        throw Exception(
          response.data['message'] ?? 'Error al restablecer la contraseña',
        );
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Error desconocido.');
      rethrow;
    }
  }

  // --- MÉTODOS DE FEED Y BÚSQUEDA ---

  Future<List<Post>> getPosts() async {
    try {
      final response = await _dio.get('/posts/');
      if (response.statusCode == 200) {
        List<dynamic> postData = response.data;
        return postData.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar las publicaciones');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Error de red al cargar publicaciones.');
      rethrow;
    }
  }

  Future<SearchResults?> search(String query) async {
    try {
      final response = await _dio.get(
        '/search/',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        return SearchResults.fromJson(response.data);
      } else {
        // En caso de error, retornar null en lugar de lanzar excepción
        print('Error en búsqueda: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Error de red en la búsqueda.');
      return null; // Importante: retornar null en caso de error
    }
  }

  // --- MANEJO DE ERRORES CENTRALIZADO ---
  void _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final errorData = e.response!.data;
      if (errorData is Map<String, dynamic>) {
        final errorMessage =
            errorData['message'] ?? errorData['detail'] ?? defaultMessage;
        throw Exception(errorMessage);
      }
    }
    throw Exception('Error de conexión. Verifica tu internet.');
  }

  Future<void> createPost({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      // El token JWT se añadirá automáticamente por el interceptor
      final response = await _dio.post(
        '/posts/',
        data: {'title': title, 'content': content, 'image_url': imageUrl},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('El servidor respondió con un error');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Error al crear la publicación.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUploadSignature() async {
    try {
      // El token JWT se añadirá automáticamente por el interceptor
      final response = await _dio.post('/posts/generate-upload-signature');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al obtener la firma para la subida.');
      rethrow;
    }
  }

  Future<void> likePost(int postId) async {
    try {
      // El token se adjuntará automáticamente por el interceptor
      await _dio.post('/posts/$postId/like', data: {});
    } on DioException catch (e) {
      _handleDioError(e, 'Error al reaccionar a la publicación.');
      rethrow;
    }
  }

  Future<void> unlikePost(int postId) async {
    try {
      await _dio.delete('/posts/$postId/like'); // <-- Usa _dio.delete
    } on DioException catch (e) {
      _handleDioError(e, 'Error al quitar la reacción.');
      rethrow;
    }
  }

  Future<List<Comment>> getComments(int postId) async {
    try {
      final response = await _dio.get('/posts/$postId/comments');
      final List<dynamic> data = response.data;
      return data.map((json) => Comment.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar comentarios.');
      rethrow;
    }
  }

  Future<Comment> postComment(int postId, String content) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/comments',
        data: {'content': content},
      );
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al publicar comentario.');
      rethrow;
    }
  }
}
