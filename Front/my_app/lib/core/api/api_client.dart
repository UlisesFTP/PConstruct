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

// --- ¡NUEVA IMPORTACIÓN DE MODELOS DE BUILDS! ---
import '../../models/build.dart'; // Importa BuildRead, BuildSummary, BuildCreate
// -------------------------------------------------

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

  Future<bool> register(
    String name,
    String username,
    String email,
    String password, {
    String? avatarUrl, // <-- AÑADE ESTE PARÁMETRO OPCIONAL
  }) async {
    try {
      // Prepara los datos
      final Map<String, dynamic> data = {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      };

      // Añade el avatar_url solo si no es nulo
      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
      }

      // Llama al endpoint de registro del gateway
      await _dio.post(
        '/auth/register', // Endpoint del API Gateway
        data: data,
      );

      // Si llega aquí, el registro (200 OK) fue exitoso
      return true;
    } on DioException catch (e) {
      // _handleDioError ya debería mostrar el error (ej. "Usuario ya existe")
      _handleDioError(e, 'Error al registrar la cuenta.');
      return false;
    } catch (e) {
      print("Error inesperado en register: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getProfileUploadSignature() async {
    try {
      // Este es el nuevo endpoint que creamos en el backend
      final response = await _dio.post('/users/generate-upload-signature');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al obtener la firma para la subida.');
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

  // --- MÉTODOS DEL SERVICIO DE COMPONENTES (Sin cambios) ---
  Future<PaginatedComponentsResponse> fetchComponents({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? brand,
    double? maxPrice,
    double? minPrice,
    String? search,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
      if (minPrice != null && minPrice > 0) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

      final response = await _dio.get(
        '/components/',
        queryParameters: queryParams,
      );

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

  Future<ComponentDetail> fetchComponentDetail(int componentId) async {
    try {
      final response = await _dio.get('/components/$componentId');
      return ComponentDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar el detalle del componente.');
      rethrow;
    }
  }

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
      if (response.data == null || response.data is! Map<String, dynamic>) {
        throw Exception(
          'La reseña fue creada pero no se recibió respuesta (Respuesta: ${response.data})',
        );
      }
      return ComponentReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al publicar la reseña.');
      rethrow;
    }
  }

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

  Future<BuildRead> createBuild(BuildCreate buildData) async {
    try {
      final response = await _dio.post(
        '/api/v1/builds/', // <-- AÑADIR /api/v1
        data: buildData.toJson(),
      );
      return BuildRead.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al crear la build.');
      rethrow;
    }
  }

  /// Llama a GET /api/v1/builds/my-builds
  Future<List<BuildSummary>> getMyBuilds() async {
    try {
      final response = await _dio.get(
        '/api/v1/builds/my-builds',
      ); // <-- AÑADIR /api/v1
      final List<dynamic> data = response.data;
      return data.map((json) => BuildSummary.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar mis builds.');
      rethrow;
    }
  }

  /// Llama a GET /api/v1/builds/community
  Future<List<BuildSummary>> getCommunityBuilds() async {
    try {
      final response = await _dio.get(
        '/api/v1/builds/community',
      ); // <-- AÑADIR /api/v1
      final List<dynamic> data = response.data;
      return data.map((json) => BuildSummary.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar las builds de la comunidad.');
      rethrow;
    }
  }

  /// Llama a GET /api/v1/builds/{buildId}
  Future<BuildRead> getBuildDetail(String buildId) async {
    try {
      final response = await _dio.get(
        '/api/v1/builds/$buildId',
      ); // <-- AÑADIR /api/v1
      return BuildRead.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar el detalle de la build.');
      rethrow;
    }
  }

  /// Llama a DELETE /api/v1/builds/{buildId}
  Future<void> deleteBuild(String buildId) async {
    try {
      await _dio.delete('/api/v1/builds/$buildId'); // <-- AÑADIR /api/v1
    } on DioException catch (e) {
      _handleDioError(e, 'Error al eliminar la build.');
      rethrow;
    }
  }

  /// Llama a POST /api/v1/builds/check-compatibility
  Future<CompatibilityResponse> checkCompatibility(
    Map<String, String?> components,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/builds/check-compatibility', // <-- AÑADIR /api/v1
        data: {'components': components},
      );
      return CompatibilityResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _handleDioError(e, 'Error al verificar la compatibilidad.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> runBenchmark(
    Map<String, dynamic> benchmarkData,
  ) async {
    try {
      // Nota: Esta ruta no usa el prefijo /api/v1 según tu benchmark_router.py
      final response = await _dio.post(
        '/benchmark/estimate',
        data: benchmarkData,
        // Aumentamos el timeout solo para esta llamada, Gemini puede tardar
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al ejecutar el benchmark.');
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

  Future<List<Post>> getMyPosts() async {
    try {
      final response = await _dio.get('/posts/me/');
      final List<dynamic> postList = response.data as List<dynamic>;
      return postList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar mis posts.');
      rethrow;
    }
  }

  // --- NUEVO: Actualizar un post ---
  Future<Post> updatePost(int postId, String title, String content) async {
    try {
      final response = await _dio.put(
        '/posts/$postId',
        data: {'title': title, 'content': content},
      );
      return Post.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al actualizar el post.');
      rethrow;
    }
  }

  // --- NUEVO: Eliminar un post ---
  Future<void> deletePost(int postId) async {
    try {
      await _dio.delete('/posts/$postId');
    } on DioException catch (e) {
      _handleDioError(e, 'Error al eliminar el post.');
      rethrow;
    }
  }
}
