import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async'; // Para el Timer de debouncing
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:my_app/core/widgets/comments_modal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    as iframe_player;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:visibility_detector/visibility_detector.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<Post>> _postsFuture;
  final Map<int, GlobalKey> _postKeys = {};

  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;

  final String _webSocketUrl = 'ws://localhost:8000/posts/ws/feed';
  // final String _webSocketUrl = 'ws://10.0.2.2:8000/posts/ws/feed'; // <-- Descomenta si usas emulador Android

  DateTime? _lastLoadTime; // Para el temporizador de 8-10 min
  bool _showNewPostsButton = false; // Para el botón "Nuevos Posts"

  @override
  void initState() {
    super.initState();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _postsFuture = apiClient.getPosts();
    _loadPosts();
    // Nos conectamos al feed en tiempo real
    _connectWebSocket();

    print("FeedPage initState: Cargando posts...");
  }

  // NUEVO: Método separado para cargar posts (para poder re-usarlo)
  void _loadPosts() {
    print("FeedPage: Cargando posts vía HTTP...");
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    // Asignamos el futuro al estado para que el FutureBuilder reaccione
    setState(() {
      _postsFuture = apiClient.getPosts();
      _lastLoadTime = DateTime.now(); // Actualiza el temporizador
      _showNewPostsButton = false; // Oculta el botón al recargar
    });
  }

  // NUEVO: Comprueba si el feed está "rancio" (más de 9 min)
  void _checkRefreshTimer() {
    if (_lastLoadTime == null) return; // Aún no ha cargado

    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);

    // Si han pasado más de 9 minutos, recarga.
    if (difference.inMinutes >= 9) {
      print("FeedPage: Datos rancios (>= 9 min) detectados, recargando...");
      _loadPosts();
    }
  }

  // NUEVO: Método para iniciar y escuchar el WebSocket
  void _connectWebSocket() {
    try {
      print("FeedPage: Conectando a WebSocket en $_webSocketUrl");
      // 1. Conectamos al canal
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));

      // 2. Escuchamos mensajes del servidor
      _channel!.stream.listen(
        (message) {
          print('WebSocket message received: $message');
          final data = jsonDecode(message);
          if (data['event'] == 'new_post') {
            setState(() {
              _showNewPostsButton = true;
            });
          }

          if (data['event'] == 'post_update' && data['action'] == 'edit') {
            _loadPosts();
          }

          if (data['event'] == 'post_delete') {
            _loadPosts();
          }
        },
        onDone: () {
          print('WebSocket channel cerrado (onDone)');
          // Opcional: intentar reconectar
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
      );
    } catch (e) {
      print("Error al conectar al WebSocket: $e");
    }
  }

  // NUEVO: Limpiamos la conexión al salir de la página
  @override
  void dispose() {
    // Cerramos la conexión del WebSocket
    _channel?.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Scrolling Logic (Placeholder - needs connection to MainLayout) ---
  // This function would be called BY MainLayout when a search result is clicked.
  // How MainLayout calls this depends on your chosen method (Callback, GlobalKey, State Management).
  void scrollToPostById(int postId) async {
    final postKey = _postKeys[postId];
    if (postKey != null && postKey.currentContext != null) {
      print("✅ FeedPage: Scroll requested for post $postId");
      await Future.delayed(const Duration(milliseconds: 50));
      Scrollable.ensureVisible(
        postKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item
      );
    } else {
      print("❌ FeedPage: No key/context for post $postId");
    }
  }

  // --- Build Method (Returns ONLY Feed Content + FAB) ---
  @override
  Widget build(BuildContext context) {
    // Usamos VisibilityDetector para saber cuándo el usuario VUELVE a esta página
    return VisibilityDetector(
      key: const Key('feed_page_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        // Si la página se vuelve completamente visible
        if (visibilityInfo.visibleFraction == 1.0) {
          print("FeedPage: Página visible. Comprobando temporizador...");
          _checkRefreshTimer(); // Comprueba si debe recargar
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF1A1A1C),
              builder: (modalContext) => CreatePostModal(
                onPostCreated: () {
                  // El WebSocket se encargará de mostrar el botón "Nuevos Posts".
                  print("Post creado. El feed se actualizará.");
                },
              ),
            );
          },
          backgroundColor: const Color.fromARGB(
            255,
            197,
            0,
            66,
          ), // Color de tu tema
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 197, 0, 69),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los posts: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.hasData) {
              final posts = snapshot.data!;
              _postKeys.clear();
              for (var post in posts) {
                _postKeys[post.id] = GlobalKey();
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      _loadPosts();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        // Combina un ancho máximo (para web) con el padding (para móvil)
                        return Center(
                          child: Container(
                            // Establece un ancho máximo para pantallas grandes (web/tablet)
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Padding(
                              // Añade padding horizontal (a los lados) y vertical (entre posts)
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0, // <-- Márgenes en móvil
                                vertical: 8.0,
                              ),
                              child: PostCard(
                                key: _postKeys[post.id],
                                post: post,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // --- EL BOTÓN DE "NUEVOS POSTS" ---
                  if (_showNewPostsButton)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              197,
                              0,
                              69,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            _loadPosts(); // Recarga al tocar el botón
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: const Text(
                            'Nuevos Posts',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  // --- FIN DEL BOTÓN ---
                ],
              );
              // --- FIN DEL Stack ---
            }
            // Fallback
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 197, 0, 66),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- ACTUALIZACIÓN DE COMPONENTES ---

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int localLikesCount;
  late bool isLiked; // Estado local para cambiar el color del icono
  bool isLoadingLike = false; // Para prevenir doble-tap

  @override
  void initState() {
    super.initState();
    localLikesCount = widget.post.likesCount;
    isLiked = widget.post.isLikedByUser;
    // NOTA: Para saber si el usuario YA le ha dado like, necesitaríamos
    // que el backend nos envíe esa info en el 'GET /posts/'.
    // Por ahora, asumimos que no le ha dado like al cargar.
  }

  void _handleLike() async {
    if (isLoadingLike) return; // Prevenir doble tap mientras carga

    setState(() {
      isLoadingLike = true;
      // Actualización optimista de la UI
      if (isLiked) {
        localLikesCount--;
        isLiked = false;
      } else {
        localLikesCount++;
        isLiked = true;
      }
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      // Llama a la API correcta según el estado anterior
      if (!isLiked) {
        // Si el estado AHORA es false, significa que ANTES era true
        await apiClient.unlikePost(widget.post.id);
      } else {
        // Si el estado AHORA es true, significa que ANTES era false
        await apiClient.likePost(widget.post.id);
      }

      // Si todo va bien, solo termina la carga
      if (mounted) {
        setState(() {
          isLoadingLike = false;
        });
      }
    } catch (e) {
      // Si la API falla, revertimos la UI al estado anterior
      if (mounted) {
        setState(() {
          if (isLiked) {
            // Si el estado optimista era true, revertimos a false
            localLikesCount--;
            isLiked = false;
          } else {
            // Si el estado optimista era false, revertimos a true
            localLikesCount++;
            isLiked = true;
          }
          isLoadingLike = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${isLiked ? 'quitar' : 'añadir'} reacción: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _buildMedia(String url) {
    // Usamos el conversor de 'youtube_player_flutter' que funciona en ambos
    final String? videoId = mobile_player.YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      // Si es un video, decidimos qué reproductor usar
      if (kIsWeb) {
        // --- CÓDIGO PARA WEB ---
        final _controller = iframe_player.YoutubePlayerController.fromVideoId(
          videoId: videoId, // <-- Ahora sí está en el lugar correcto
          autoPlay: false, // <-- Y este también
          params: const iframe_player.YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            // 'autoPlay' se movió arriba
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: iframe_player.YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        );
      } else {
        // --- CÓDIGO PARA ANDROID / iOS ---
        final _controller = mobile_player.YoutubePlayerController(
          initialVideoId: videoId,
          flags: const mobile_player.YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: mobile_player.YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            aspectRatio: 16 / 9,
          ),
        );
      }
    } else {
      // Si no es un video, es una imagen (esta lógica se mantiene)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // ... (tu errorBuilder se mantiene igual)
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el tiempo transcurrido de forma legible
    final timeAgoString = timeago.format(widget.post.createdAt, locale: 'es');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.post.authorAvatarUrl != null
                        ? NetworkImage(widget.post.authorAvatarUrl!)
                        : null,
                    child: widget.post.authorAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorUsername ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgoString,
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.content,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              if (widget.post.imageUrl != null &&
                  widget.post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildMedia(
                  widget.post.imageUrl!,
                ), // Llama a la nueva función condicional
              ],
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _handleLike, // <-- Llama a la función
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.whatshot
                                : Icons.whatshot_outlined, // Icono dinámico
                            color: isLiked
                                ? const Color(0xFFC7384D)
                                : const Color(0xFFA0A0A0), // Color dinámico
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localLikesCount
                                .toString(), // <-- Usa el contador local
                            style: TextStyle(
                              color: isLiked
                                  ? const Color(0xFFC7384D)
                                  : const Color(0xFFA0A0A0),
                              fontSize: 15,
                              fontWeight: isLiked
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- FIN DE LA MODIFICACIÓN ---
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                            true, // Para que el modal respete el teclado
                        backgroundColor: const Color(
                          0xFF1A1A1C,
                        ), // Color del modal
                        builder: (modalContext) {
                          // Pasamos el postId al modal
                          return CommentsModal(postId: widget.post.id);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFFA0A0A0),
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Comentarios",
                            style: TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
