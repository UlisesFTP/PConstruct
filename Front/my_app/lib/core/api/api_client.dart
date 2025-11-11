import 'package:dio/dio.dart';
import 'package:my_app/providers/auth_provider.dart'; // <-- IMPORTANTE

// --- Importaciones de Modelos ---
import '../../models/posts.dart';
import '../../models/search_results.dart';
import '../../models/comment.dart'; // Este es el de Posts

// --- ¡NUEVAS IMPORTACIONES DE MODELOS DE COMPONENTES! ---
import '../../models/component.dart'; // Importa ComponentCard y ComponentDetail
import '../../models/component_review.dart';
import '../../models/comment_componente.dart';
// ---------------------------------------------------

// --- Clase auxiliar para la respuesta paginada ---
class PaginatedComponentsResponse {
  final List<ComponentCard> components;
  final int totalItems;

  PaginatedComponentsResponse({
    required this.components,
    required this.totalItems,
  });
}
// ---------------------------------------------------

class ApiClient {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:8000'; // URL del API Gateway
  final AuthProvider? authProvider;

  ApiClient({this.authProvider}) {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // El interceptor existente añade el token a todas las rutas
          // excepto login y register, lo cual es perfecto.
          if (options.path != '/auth/login' &&
              options.path != '/auth/register') {
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

  // --- MÉTODOS DE AUTENTICACIÓN (Sin cambios) ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final responseData = response.data;
      if (responseData.containsKey('access_token')) {
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

  // ... (El resto de tus métodos de auth/verify/reset... se mantienen igual) ...
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

  // --- MÉTODOS DE POSTS Y BÚSQUEDA (Sin cambios) ---
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
    // ... (tu método de búsqueda se mantiene igual) ...
    try {
      final response = await _dio.get(
        '/search/',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        return SearchResults.fromJson(response.data);
      } else {
        print('Error en búsqueda: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Error de red en la búsqueda.');
      return null;
    }
  }

  // ... (tus otros métodos de posts: createPost, like, comments... se mantienen igual) ...
  Future<void> createPost({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
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
      final response = await _dio.post('/posts/generate-upload-signature');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al obtener la firma para la subida.');
      rethrow;
    }
  }

  Future<void> likePost(int postId) async {
    try {
      await _dio.post('/posts/$postId/like', data: {});
    } on DioException catch (e) {
      _handleDioError(e, 'Error al reaccionar a la publicación.');
      rethrow;
    }
  }

  Future<void> unlikePost(int postId) async {
    try {
      await _dio.delete('/posts/$postId/like');
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

  // --- ¡NUEVOS MÉTODOS DEL SERVICIO DE COMPONENTES! ---

  /// Llama a GET /components/
  /// Obtiene la lista paginada y filtrada de componentes.
  Future<PaginatedComponentsResponse> fetchComponents({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? brand,
    double? maxPrice,
    String? search,
    String? sortBy,
  }) async {
    try {
      // 1. Construir los Query Parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

      // 2. Hacer la llamada (la ruta base es '/components' del router del gateway)
      final response = await _dio.get(
        '/components/',
        queryParameters: queryParams,
      );

      // 3. Parsear la respuesta
      final data = response.data as Map<String, dynamic>;
      final itemsList = (data['items'] as List<dynamic>)
          .map((item) => ComponentCard.fromJson(item as Map<String, dynamic>))
          .toList();

      return PaginatedComponentsResponse(
        components: itemsList,
        totalItems: data['total_items'] as int,
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar los componentes.');
      rethrow;
    }
  }

  /// Llama a GET /components/{componentId}
  /// Obtiene el detalle completo de un componente.
  Future<ComponentDetail> fetchComponentDetail(int componentId) async {
    try {
      final response = await _dio.get('/components/$componentId');
      return ComponentDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar el detalle del componente.');
      rethrow;
    }
  }

  /// Llama a POST /components/{componentId}/reviews
  /// (Ruta Protegida) Publica una nueva reseña.
  Future<ComponentReview> postReview({
    required int componentId,
    required int rating,
    String? title,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/components/$componentId/reviews',
        data: {'rating': rating, 'title': title, 'content': content},
      );
      return ComponentReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al publicar la reseña.');
      rethrow;
    }
  }

  /// Llama a POST /components/{componentId}/reviews/{reviewId}/comments
  /// (Ruta Protegida) Publica un nuevo comentario en una reseña.
  Future<CommentComponente> postCommentOnReview({
    required int componentId,
    required int reviewId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/components/$componentId/reviews/$reviewId/comments',
        data: {'content': content},
      );
      return CommentComponente.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al publicar el comentario.');
      rethrow;
    }
  }

  // --- MANEJO DE ERRORES CENTRALIZADO (Sin cambios) ---
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
}
