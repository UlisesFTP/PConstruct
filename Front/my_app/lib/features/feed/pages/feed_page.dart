import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/post_card.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:math'; // Importante para Random()

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // --- ESTADO PARA INFINITE SCROLL ---
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _postKeys = {};

  List<Post> _posts = []; // La lista acumulativa de posts
  bool _isLoadingInitial = true; // Carga inicial (pantalla completa)
  bool _isLoadingMore = false; // Carga de paginación (spinner abajo)
  bool _hasMore = true; // ¿Quedan posts en el servidor?
  int _page = 1; // Página actual
  int _currentSeed = 0; // Semilla para mantener el orden
  String _error = ''; // Manejo de errores

  // --- WEBSOCKET ---
  WebSocketChannel? _channel;
  final String _webSocketUrl = 'ws://localhost:8000/posts/ws/feed';
  bool _showNewPostsButton = false;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();

    // 1. Configurar Listener del Scroll
    _scrollController.addListener(_scrollListener);

    // 2. Carga Inicial
    _loadInitialPosts();

    // 3. Conectar WebSocket
    _connectWebSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // No olvidar limpiar el controller
    _channel?.sink.close();
    super.dispose();
  }

  // --- DETECTOR DE SCROLL ---
  void _scrollListener() {
    // Si llegamos al final (menos 200px de margen) y no estamos cargando...
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  // --- CARGA INICIAL (o Refresco) ---
  Future<void> _loadInitialPosts() async {
    // Evitamos setState si el widget ya no está montado
    if (!mounted) return;

    setState(() {
      _isLoadingInitial = true;
      _error = '';
      // Generamos NUEVA semilla para cambiar el orden aleatorio al refrescar
      _currentSeed = Random().nextInt(100000);
      _page = 1; // Reseteamos a página 1
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      // Pedimos la página 1
      final newPosts = await apiClient.getPosts(
        page: 1,
        seed: _currentSeed,
        sortBy: 'popular',
      );

      if (!mounted) return;

      setState(() {
        _posts = newPosts;
        _isLoadingInitial = false;
        _lastLoadTime = DateTime.now();
        _showNewPostsButton = false;
        // Si llegaron menos de 20, es que no hay más páginas
        _hasMore = newPosts.length >= 20;

        // Generar Keys para mantener el estado de los videos/imágenes
        _postKeys.clear();
        for (var post in _posts) {
          _postKeys[post.id] = GlobalKey();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _error = e.toString();
      });
    }
  }

  // --- CARGAR MÁS (Paginación) ---
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      final nextPage = _page + 1;

      // IMPORTANTE: Usamos la MISMA _currentSeed para que no salgan repetidos
      final morePosts = await apiClient.getPosts(
        page: nextPage,
        seed: _currentSeed,
        sortBy: 'popular',
      );

      if (!mounted) return;

      setState(() {
        if (morePosts.isEmpty) {
          _hasMore = false; // Se acabó el feed
        } else {
          // Añadimos los nuevos posts a la lista existente
          _posts.addAll(morePosts);
          _page = nextPage;

          // Generar Keys para los nuevos
          for (var post in morePosts) {
            _postKeys[post.id] = GlobalKey();
          }

          // Si llegaron menos de 20, asumimos que es el final
          if (morePosts.length < 20) _hasMore = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        // Podrías mostrar un SnackBar aquí si falla la carga de más posts
      });
    }
  }

  // --- LÓGICA DE TEMPORIZADOR Y WEBSOCKET ---
  void _checkRefreshTimer() {
    if (_lastLoadTime == null) return;
    final difference = DateTime.now().difference(_lastLoadTime!);
    // Si pasaron más de 9 minutos, recargamos para tener contenido fresco
    if (difference.inMinutes >= 9) {
      print("Datos rancios, recargando...");
      _loadInitialPosts();
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['event'] == 'new_post') {
          setState(() => _showNewPostsButton = true);
        }
        // Si se edita o borra, recargamos para mantener consistencia
        // (En una app más compleja, actualizarías solo el item localmente)
        if (data['event'] == 'post_update' || data['event'] == 'post_delete') {
          _loadInitialPosts();
        }
      });
    } catch (e) {
      print("Error WebSocket: $e");
    }
  }

  void scrollToPostById(int postId) async {
    final postKey = _postKeys[postId];
    if (postKey != null && postKey.currentContext != null) {
      await Future.delayed(const Duration(milliseconds: 50));
      Scrollable.ensureVisible(
        postKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('feed_page_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1.0) {
          _checkRefreshTimer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildFloatingActionButton(),
        body: Stack(
          children: [
            _buildMainContent(),
            if (_showNewPostsButton) _buildNewPostsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoadingInitial) {
      return _buildLoadingIndicator();
    }

    if (_error.isNotEmpty) {
      return _buildErrorWidget(_error);
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          "No hay publicaciones aún.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: const Color(0xFF1A1A1C),
      color: const Color.fromARGB(255, 197, 0, 69),
      onRefresh: _loadInitialPosts, // Conectar al Pull-to-Refresh
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        // +1 item al final para el spinner de carga inferior
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Si es el último item y estamos cargando, mostramos spinner
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 197, 0, 69),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final post = _posts[index];
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 8.0,
                ),
                child: PostCard(key: _postKeys[post.id], post: post),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1A1A1C),
          builder: (modalContext) => CreatePostModal(
            onPostCreated: () {
              // Al crear, recargamos para ver el nuevo post arriba
              _loadInitialPosts();
            },
          ),
        );
      },
      backgroundColor: const Color.fromARGB(255, 197, 0, 66),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 197, 0, 69).withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.whatshot,
                    color: const Color.fromARGB(255, 197, 0, 69),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando contenido...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los posts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInitialPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 197, 0, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPostsButton() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 197, 0, 66),
                    Color.fromARGB(255, 155, 0, 52),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  _loadInitialPosts();
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Nuevos Posts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
