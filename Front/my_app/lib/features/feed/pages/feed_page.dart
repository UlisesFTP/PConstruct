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

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<Post>> _postsFuture;
  final Map<int, GlobalKey> _postKeys = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _postsFuture = apiClient.getPosts();
    print("FeedPage initState: Cargando posts...");
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller
    // _debounce?.cancel(); // Dispose moved to MainLayout
    super.dispose();
  }

  // --- Core Feed Logic ---
  Future<void> _refreshPosts() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    // Trigger FutureBuilder rebuild
    setState(() {
      _postsFuture = apiClient.getPosts();
    });
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
    // isDesktop might still be useful for responsive padding inside the feed
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    // Return a basic Scaffold mainly for the FloatingActionButton placement
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background is handled by MainLayout
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: Theme.of(context).primaryColor,
        backgroundColor: const Color(
          0xFF1A1A1C,
        ), // Or inherit/set appropriately
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            // --- Handle Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Handle Error State ---
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar las publicaciones: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              );
            }

            // --- Handle No Data or Empty State ---
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Aún no hay publicaciones. ¡Sé el primero!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // --- Handle Data State (Build the List) ---
            final posts = snapshot.data!;

            // Regenerate keys after the frame builds if data changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Check if keys need update (e.g., if post list changed)
                bool needsUpdate = false;
                if (_postKeys.length != posts.length) {
                  needsUpdate = true;
                } else {
                  for (var post in posts) {
                    if (!_postKeys.containsKey(post.id)) {
                      needsUpdate = true;
                      break;
                    }
                  }
                }
                if (needsUpdate) {
                  setState(() {
                    _postKeys.clear();
                    for (var post in posts) {
                      _postKeys[post.id] = GlobalKey();
                    }
                  });
                }
              }
            });

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 24,
                vertical: isDesktop ? 32 : 24,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                // Get the key, defaulting to null if not ready yet
                final postKey = _postKeys[post.id];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: PostCard(
                        // Assign the key to the PostCard
                        key: postKey,
                        post: post,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // --- Floating Action Button specific to the Feed ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A1C),
            builder: (modalContext) =>
                CreatePostModal(onPostCreated: _refreshPosts),
          );
        },
        backgroundColor: const Color(0xFFC7384D),
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Crear Publicación",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
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
